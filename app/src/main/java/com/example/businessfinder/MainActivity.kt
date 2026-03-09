package com.example.businessfinder

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.businessfinder.databinding.ActivityMainBinding
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private lateinit var businessAdapter: BusinessAdapter
    private val businessList = mutableListOf<Business>()
    private val executor = Executors.newSingleThreadExecutor()
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Apply saved language
        val savedLang = LanguageHelper.getSavedLanguage(this)
        LanguageHelper.setLanguage(this, savedLang)
        
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Setup language spinner
        setupLanguageSpinner()

        // Setup RecyclerView
        businessAdapter = BusinessAdapter(businessList) { business, isChecked ->
            business.isSelected = isChecked
        }
        binding.rvResults.layoutManager = LinearLayoutManager(this)
        binding.rvResults.adapter = businessAdapter

        // Search button
        binding.btnSearch.setOnClickListener {
            performSearch()
        }

        // Select all
        binding.cbSelectAll.setOnCheckedChangeListener { _, isChecked ->
            businessList.forEach { it.isSelected = isChecked }
            businessAdapter.notifyDataSetChanged()
        }

        // Bulk email
        binding.btnEmail.setOnClickListener {
            sendBulkEmail()
        }

        // Bulk WhatsApp
        binding.btnWhatsapp.setOnClickListener {
            sendBulkWhatsApp()
        }

        // Check license
        if (!LicenseManager.isLicenseValid(this)) {
            startActivity(Intent(this, LicenseActivity::class.java))
            finish()
        }
    }

    private fun setupLanguageSpinner() {
        val languages = arrayOf("English", "اردو", "العربية")
        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, languages)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.languageSpinner.adapter = adapter

        val currentLang = LanguageHelper.getSavedLanguage(this)
        binding.languageSpinner.setSelection(when(currentLang) {
            "ur" -> 1
            "ar" -> 2
            else -> 0
        })

        binding.languageSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>, view: View, position: Int, id: Long) {
                val newLang = when(position) {
                    1 -> "ur"
                    2 -> "ar"
                    else -> "en"
                }
                if (newLang != LanguageHelper.getSavedLanguage(this@MainActivity)) {
                    LanguageHelper.setLanguage(this@MainActivity, newLang)
                    recreate()
                }
            }
            override fun onNothingSelected(parent: AdapterView<*>) {}
        }
    }

    private fun performSearch() {
        val businessType = binding.etBusinessType.text.toString().trim()
        if (businessType.isEmpty()) {
            Toast.makeText(this, getString(R.string.enter_business_type), Toast.LENGTH_SHORT).show()
            return
        }

        val country = binding.etCountry.text.toString().trim()
        val city = binding.etCity.text.toString().trim()
        val area = binding.etArea.text.toString().trim()

        // Build query string for Nominatim
        val query = buildString {
            append(businessType)
            if (area.isNotEmpty()) append(" $area")
            if (city.isNotEmpty()) append(" $city")
            if (country.isNotEmpty()) append(" $country")
        }

        // Show loading
        Toast.makeText(this, "Searching...", Toast.LENGTH_SHORT).show()

        // Execute network request in background
        executor.execute {
            searchWithNominatim(query)
        }
    }

    private fun searchWithNominatim(query: String) {
        try {
            // Encode query for URL
            val encodedQuery = java.net.URLEncoder.encode(query, "UTF-8")
            val urlString = "https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=50"
            val url = URL(urlString)
            
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.setRequestProperty("User-Agent", "BusinessFinder-App/1.0") // Required by Nominatim
            
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    response.append(line)
                }
                reader.close()
                
                // Parse JSON
                parseNominatimResponse(response.toString())
            } else {
                showError("Error: $responseCode")
            }
            connection.disconnect()
        } catch (e: Exception) {
            showError("Exception: ${e.message}")
        }
    }

    private fun parseNominatimResponse(jsonString: String) {
        try {
            val jsonArray = JSONArray(jsonString)
            businessList.clear()
            
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val displayName = obj.getString("display_name")
                val lat = obj.optString("lat", "")
                val lon = obj.optString("lon", "")
                val address = obj.optJSONObject("address")
                
                // Extract useful fields
                val name = displayName.split(",").firstOrNull() ?: "Unknown"
                val phone = "" // Nominatim doesn't provide phone numbers directly
                val website = "" // Nominatim doesn't provide websites
                
                businessList.add(
                    Business(
                        name = name,
                        address = displayName,
                        phone = phone,
                        website = website,
                        isSelected = false
                    )
                )
            }
            
            handler.post {
                binding.tvResultsCount.text = getString(R.string.results_found, businessList.size)
                businessAdapter.notifyDataSetChanged()
            }
        } catch (e: Exception) {
            showError("Parse error: ${e.message}")
        }
    }

    private fun showError(message: String) {
        handler.post {
            Toast.makeText(this, message, Toast.LENGTH_LONG).show()
        }
    }

    private fun sendBulkEmail() {
        val selected = businessList.filter { it.isSelected }
        if (selected.isEmpty()) {
            Toast.makeText(this, getString(R.string.select_businesses), Toast.LENGTH_SHORT).show()
            return
        }
        // Since we don't have emails, show a message
        Toast.makeText(this, "Emails not available in OpenStreetMap data. Use phone numbers or manual entry.", Toast.LENGTH_LONG).show()
        
        // Alternative: Open email app with empty recipients
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, "Your Subject Here")
            putExtra(Intent.EXTRA_TEXT, "Your message here")
        }
        startActivity(Intent.createChooser(intent, "Send Email"))
    }

    private fun sendBulkWhatsApp() {
        val selected = businessList.filter { it.isSelected }
        if (selected.isEmpty()) {
            Toast.makeText(this, getString(R.string.select_businesses), Toast.LENGTH_SHORT).show()
            return
        }
        // Nominatim doesn't provide phone numbers
        Toast.makeText(this, "Phone numbers not available in OpenStreetMap data. You may need to collect manually.", Toast.LENGTH_LONG).show()
        
        // Just open WhatsApp to a default number (or none)
        val uri = Uri.parse("https://wa.me/?text=${Uri.encode("Hello, I am interested in your services.")}")
        startActivity(Intent(Intent.ACTION_VIEW, uri))
    }
}
