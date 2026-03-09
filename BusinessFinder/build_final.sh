#!/bin/bash

echo "🚀 آخری بار، پورا پروجیکٹ بنا رہا ہے..."

# گرینڈل فائلیں
cat > build.gradle << 'GRADLE'
plugins {
    id 'com.android.application' version '8.1.0' apply false
    id 'com.android.library' version '8.1.0' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.0' apply false
}
GRADLE

cat > settings.gradle << 'SETTINGS'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "BusinessFinder"
include ':app'
SETTINGS

mkdir -p gradle/wrapper
cat > gradle/wrapper/gradle-wrapper.properties << 'WRAPPER'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
WRAPPER

# گریڈل وریپر ڈاؤن لوڈ کریں
wget -q https://raw.githubusercontent.com/gradle/gradle/master/gradlew
wget -q https://raw.githubusercontent.com/gradle/gradle/master/gradlew.bat
mkdir -p gradle/wrapper
wget -q -O gradle/wrapper/gradle-wrapper.jar https://github.com/gradle/gradle/raw/master/gradle/wrapper/gradle-wrapper.jar
chmod +x gradlew

# app/build.gradle
mkdir -p app
cat > app/build.gradle << 'APPGRADLE'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.example.businessfinder'
    compileSdk 34

    defaultConfig {
        applicationId "com.example.businessfinder"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
    buildFeatures {
        viewBinding true
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.2'
    implementation 'com.google.android.gms:play-services-maps:18.2.0'
    implementation 'com.google.android.libraries.places:places:3.3.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'androidx.browser:browser:1.7.0'
}
APPGRADLE

cat > app/proguard-rules.pro << 'PROGUARD'
-keep class com.google.android.libraries.places.** { *; }
PROGUARD

# AndroidManifest.xml
mkdir -p app/src/main
cat > app/src/main/AndroidManifest.xml << 'MANIFEST'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <application
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@drawable/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@drawable/ic_launcher"
        android:supportsRtl="true"
        android:theme="@style/Theme.BusinessFinder">

        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_API_KEY_HERE" />

        <activity
            android:name=".LicenseActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
        <activity
            android:name=".MainActivity"
            android:exported="false" />
    </application>
</manifest>
MANIFEST

# جاوا فائلیں
mkdir -p app/src/main/java/com/example/businessfinder

cat > app/src/main/java/com/example/businessfinder/Business.kt << 'BUS'
package com.example.businessfinder

data class Business(
    val name: String,
    val address: String,
    val phone: String,
    val website: String,
    val email: String = "",
    val placeId: String = "",
    var isSelected: Boolean = false
)
BUS

cat > app/src/main/java/com/example/businessfinder/LanguageHelper.kt << 'LANG'
package com.example.businessfinder

import android.content.Context
import android.os.Build
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import java.util.Locale

object LanguageHelper {
    
    val availableLanguages = mapOf(
        "en" to "English",
        "ur" to "اردو",
        "ar" to "العربية"
    )
    
    fun setLanguage(context: Context, languageCode: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val localeList = LocaleListCompat.create(Locale(languageCode))
            AppCompatDelegate.setApplicationLocales(localeList)
        } else {
            val locale = Locale(languageCode)
            Locale.setDefault(locale)
            val config = context.resources.configuration
            config.setLocale(locale)
            context.resources.updateConfiguration(config, context.resources.displayMetrics)
        }
        saveLanguagePreference(context, languageCode)
    }
    
    fun getSavedLanguage(context: Context): String {
        val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
        return prefs.getString("language", "en") ?: "en"
    }
    
    private fun saveLanguagePreference(context: Context, languageCode: String) {
        val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("language", languageCode).apply()
    }
}
LANG

cat > app/src/main/java/com/example/businessfinder/LicenseManager.kt << 'LM'
package com.example.businessfinder

import android.content.Context
import android.util.Base64
import javax.crypto.Cipher
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec
import java.security.MessageDigest
import java.util.Date

object LicenseManager {
    private const val PREFS_NAME = "license_prefs"
    private const val KEY_LICENSE = "license_data"
    private const val SECRET_KEY = "MySecretKey12345"

    private fun getSecretKey(): SecretKey {
        val key = MessageDigest.getInstance("SHA-256").digest(SECRET_KEY.toByteArray()).copyOf(16)
        return SecretKeySpec(key, "AES")
    }

    fun encrypt(data: String): String {
        val cipher = Cipher.getInstance("AES")
        cipher.init(Cipher.ENCRYPT_MODE, getSecretKey())
        return Base64.encodeToString(cipher.doFinal(data.toByteArray()), Base64.DEFAULT)
    }

    fun decrypt(encryptedData: String): String {
        val cipher = Cipher.getInstance("AES")
        cipher.init(Cipher.DECRYPT_MODE, getSecretKey())
        return String(cipher.doFinal(Base64.decode(encryptedData, Base64.DEFAULT)))
    }

    fun validateLicense(context: Context, licenseCode: String): Boolean {
        return try {
            val decrypted = decrypt(licenseCode)
            val parts = decrypted.split("|")
            if (parts.size != 4) return false
            val expiry = parts[1].toLong()
            Date().time < expiry
        } catch (e: Exception) {
            false
        }
    }

    fun saveLicense(context: Context, licenseCode: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_LICENSE, licenseCode).apply()
    }

    fun isLicenseValid(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val code = prefs.getString(KEY_LICENSE, null) ?: return false
        return validateLicense(context, code)
    }
}
LM

cat > app/src/main/java/com/example/businessfinder/LicenseActivity.kt << 'LACT'
package com.example.businessfinder

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.businessfinder.databinding.ActivityLicenseBinding

class LicenseActivity : AppCompatActivity() {
    private lateinit var binding: ActivityLicenseBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLicenseBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.btnActivate.setOnClickListener {
            val code = binding.etLicenseCode.text.toString().trim()
            if (code.isNotEmpty()) {
                if (LicenseManager.validateLicense(this, code)) {
                    LicenseManager.saveLicense(this, code)
                    Toast.makeText(this, getString(R.string.license_activated), Toast.LENGTH_SHORT).show()
                    startActivity(Intent(this, MainActivity::class.java))
                    finish()
                } else {
                    Toast.makeText(this, getString(R.string.invalid_license), Toast.LENGTH_SHORT).show()
                }
            } else {
                Toast.makeText(this, getString(R.string.enter_code), Toast.LENGTH_SHORT).show()
            }
        }
    }
}
LACT

cat > app/src/main/java/com/example/businessfinder/MainActivity.kt << 'MAIN'
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
        
        val savedLang = LanguageHelper.getSavedLanguage(this)
        LanguageHelper.setLanguage(this, savedLang)
        
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupLanguageSpinner()
        setupRecyclerView()
        setupClickListeners()

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

    private fun setupRecyclerView() {
        businessAdapter = BusinessAdapter(businessList) { business, isChecked ->
            business.isSelected = isChecked
        }
        binding.rvResults.layoutManager = LinearLayoutManager(this)
        binding.rvResults.adapter = businessAdapter
    }

    private fun setupClickListeners() {
        binding.btnSearch.setOnClickListener { performSearch() }
        binding.cbSelectAll.setOnCheckedChangeListener { _, isChecked ->
            businessList.forEach { it.isSelected = isChecked }
            businessAdapter.notifyDataSetChanged()
        }
        binding.btnEmail.setOnClickListener { sendBulkEmail() }
        binding.btnWhatsapp.setOnClickListener { sendBulkWhatsApp() }
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

        val query = buildString {
            append(businessType)
            if (area.isNotEmpty()) append(" $area")
            if (city.isNotEmpty()) append(" $city")
            if (country.isNotEmpty()) append(" $country")
        }

        Toast.makeText(this, "Searching...", Toast.LENGTH_SHORT).show()
        executor.execute { searchWithNominatim(query) }
    }

    private fun searchWithNominatim(query: String) {
        try {
            val encodedQuery = java.net.URLEncoder.encode(query, "UTF-8")
            val urlString = "https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=50"
            val url = URL(urlString)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.setRequestProperty("User-Agent", "BusinessFinder-App/1.0")
            
            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) response.append(line)
                reader.close()
                parseNominatimResponse(response.toString())
            } else {
                showError("Error: ${connection.responseCode}")
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
                val name = displayName.split(",").firstOrNull() ?: "Unknown"
                businessList.add(Business(name = name, address = displayName, phone = "", website = ""))
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
        handler.post { Toast.makeText(this, message, Toast.LENGTH_LONG).show() }
    }

    private fun sendBulkEmail() {
        val selected = businessList.filter { it.isSelected }
        if (selected.isEmpty()) {
            Toast.makeText(this, getString(R.string.select_businesses), Toast.LENGTH_SHORT).show()
            return
        }
        Toast.makeText(this, "Emails not available in OpenStreetMap data.", Toast.LENGTH_LONG).show()
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
        Toast.makeText(this, "Phone numbers not available in OpenStreetMap data.", Toast.LENGTH_LONG).show()
        val uri = Uri.parse("https://wa.me/?text=${Uri.encode("Hello, I am interested in your services.")}")
        startActivity(Intent(Intent.ACTION_VIEW, uri))
    }
}
MAIN

cat > app/src/main/java/com/example/businessfinder/BusinessAdapter.kt << 'ADAPTER'
package com.example.businessfinder

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.example.businessfinder.databinding.ItemBusinessBinding

class BusinessAdapter(
    private val businesses: List<Business>,
    private val onCheckedChange: (Business, Boolean) -> Unit
) : RecyclerView.Adapter<BusinessAdapter.ViewHolder>() {

    class ViewHolder(val binding: ItemBusinessBinding) : RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemBusinessBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val business = businesses[position]
        holder.binding.tvName.text = business.name
        holder.binding.tvPhone.text = business.phone
        holder.binding.tvWebsite.text = business.website
        holder.binding.cbSelected.isChecked = business.isSelected
        holder.binding.cbSelected.setOnCheckedChangeListener { _, isChecked ->
            onCheckedChange(business, isChecked)
        }
    }

    override fun getItemCount() = businesses.size
}
ADAPTER

# ریزورسز
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/values-ur
mkdir -p app/src/main/res/values-ar
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/xml

cat > app/src/main/res/values/strings.xml << 'STR'
<resources>
    <string name="app_name">Business Finder</string>
    <string name="search_hint">Enter business type...</string>
    <string name="country">Country</string>
    <string name="city">City</string>
    <string name="area">Area/Town</string>
    <string name="search_btn">Search</string>
    <string name="send_email">Send Bulk Email</string>
    <string name="send_whatsapp">Send Bulk WhatsApp</string>
    <string name="select_all">Select All</string>
    <string name="results_found">%d businesses found</string>
    <string name="enter_business_type">Please enter business type</string>
    <string name="select_businesses">Please select at least one business</string>
    <string name="no_emails">No email addresses found</string>
    <string name="no_phones">No phone numbers found</string>
    <string name="google_maps_key">YOUR_API_KEY</string>
    <string name="license_activated">License activated successfully</string>
    <string name="invalid_license">Invalid license code</string>
    <string name="enter_code">Please enter license code</string>
</resources>
STR

cat > app/src/main/res/values-ur/strings.xml << 'STRUR'
<resources>
    <string name="app_name">کاروبار تلاش کریں</string>
    <string name="search_hint">کاروبار کی قسم لکھیں...</string>
    <string name="country">ملک</string>
    <string name="city">شہر</string>
    <string name="area">علاقہ</string>
    <string name="search_btn">تلاش کریں</string>
    <string name="send_email">بلک ای میل بھیجیں</string>
    <string name="send_whatsapp">بلک واٹس ایپ بھیجیں</string>
    <string name="select_all">تمام منتخب کریں</string>
    <string name="results_found">%d کاروبار ملے</string>
    <string name="enter_business_type">براہ کرم کاروبار کی قسم لکھیں</string>
    <string name="select_businesses">براہ کرم کم از کم ایک کاروبار منتخب کریں</string>
    <string name="no_emails">کوئی ای میل پتہ نہیں ملا</string>
    <string name="no_phones">کوئی فون نمبر نہیں ملا</string>
    <string name="google_maps_key">YOUR_API_KEY</string>
    <string name="license_activated">لائسنس کامیابی سے فعال ہو گیا</string>
    <string name="invalid_license">غلط لائسنس کوڈ</string>
    <string name="enter_code">براہ کرم لائسنس کوڈ درج کریں</string>
</resources>
STRUR

cat > app/src/main/res/values-ar/strings.xml << 'STRAR'
<resources>
    <string name="app_name">الباحث عن الأعمال</string>
    <string name="search_hint">أدخل نوع العمل...</string>
    <string name="country">البلد</string>
    <string name="city">المدينة</string>
    <string name="area">المنطقة</string>
    <string name="search_btn">بحث</string>
    <string name="send_email">إرسال بريد إلكتروني جماعي</string>
    <string name="send_whatsapp">إرسال واتساب جماعي</string>
    <string name="select_all">تحديد الكل</string>
    <string name="results_found">تم العثور على %d نشاط تجاري</string>
    <string name="enter_business_type">الرجاء إدخال نوع العمل</string>
    <string name="select_businesses">الرجاء تحديد نشاط تجاري واحد على الأقل</string>
    <string name="no_emails">لم يتم العثور على عناوين بريد إلكتروني</string>
    <string name="no_phones">لم يتم العثور على أرقام هواتف</string>
    <string name="google_maps_key">YOUR_API_KEY</string>
    <string name="license_activated">تم تفعيل الترخيص بنجاح</string>
    <string name="invalid_license">رمز الترخيص غير صالح</string>
    <string name="enter_code">الرجاء إدخال رمز الترخيص</string>
</resources>
STRAR

cat > app/src/main/res/values/colors.xml << 'COL'
<resources>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
    <color name="white">#FFFFFFFF</color>
    <color name="black">#FF000000</color>
</resources>
COL

cat > app/src/main/res/values/themes.xml << 'THEME'
<resources>
    <style name="Theme.BusinessFinder" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryVariant">@color/purple_700</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorSecondary">@color/teal_200</item>
    </style>
</resources>
THEME

cat > app/src/main/res/layout/activity_main.xml << 'MAINLAYOUT'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">

    <Spinner android:id="@+id/language_spinner"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="16dp"/>

    <com.google.android.material.textfield.TextInputLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="@string/search_hint">
        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/et_business_type"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"/>
    </com.google.android.material.textfield.TextInputLayout>

    <com.google.android.material.textfield.TextInputLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="@string/country">
        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/et_country"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"/>
    </com.google.android.material.textfield.TextInputLayout>

    <com.google.android.material.textfield.TextInputLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="@string/city">
        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/et_city"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"/>
    </com.google.android.material.textfield.TextInputLayout>

    <com.google.android.material.textfield.TextInputLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="@string/area">
        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/et_area"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"/>
    </com.google.android.material.textfield.TextInputLayout>

    <Button android:id="@+id/btn_search"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="@string/search_btn"
        android:layout_marginTop="16dp"/>

    <TextView android:id="@+id/tv_results_count"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"/>

    <CheckBox android:id="@+id/cb_select_all"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="@string/select_all"
        android:layout_marginTop="8dp"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rv_results"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:layout_marginTop="8dp"/>

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:layout_marginTop="16dp">
        <Button android:id="@+id/btn_email"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="@string/send_email"
            android:layout_marginEnd="8dp"/>
        <Button android:id="@+id/btn_whatsapp"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="@string/send_whatsapp"/>
    </LinearLayout>
</LinearLayout>
MAINLAYOUT

cat > app/src/main/res/layout/activity_license.xml << 'LICLAYOUT'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Enter License Code"
        android:textSize="24sp"
        android:layout_marginBottom="32dp"/>

    <com.google.android.material.textfield.TextInputLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="License Code">
        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/et_license_code"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"/>
    </com.google.android.material.textfield.TextInputLayout>

    <Button
        android:id="@+id/btn_activate"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Activate"
        android:layout_marginTop="16dp"/>
</LinearLayout>
LICLAYOUT

cat > app/src/main/res/layout/item_business.xml << 'ITEM'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="horizontal"
    android:padding="8dp">

    <CheckBox android:id="@+id/cb_selected"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginEnd="8dp"/>

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:orientation="vertical">
        <TextView android:id="@+id/tv_name"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:textStyle="bold"/>
        <TextView android:id="@+id/tv_phone"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"/>
        <TextView android:id="@+id/tv_website"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:autoLink="web"/>
    </LinearLayout>
</LinearLayout>
ITEM

cat > app/src/main/res/drawable/ic_launcher.xml << 'ICON'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF6200EE"
        android:pathData="M12,2C8.13,2 5,5.13 5,9c0,5.25 7,13 7,13s7,-7.75 7,-13c0,-3.87 -3.13,-7 -7,-7zM12,11.5c-1.38,0 -2.5,-1.12 -2.5,-2.5s1.12,-2.5 2.5,-2.5 2.5,1.12 2.5,2.5 -1.12,2.5 -2.5,2.5z"/>
</vector>
ICON

# xml فائلیں (یہی غائب تھیں)
cat > app/src/main/res/xml/data_extraction_rules.xml << 'DATARULES'
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <!-- کوئی قواعد نہیں -->
</data-extraction-rules>
DATARULES

cat > app/src/main/res/xml/backup_rules.xml << 'BACKUPRULES'
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <!-- کوئی بیک اپ قواعد نہیں -->
</full-backup-content>
BACKUPRULES

# gradle.properties (AndroidX اور وارننگ دبانے کے لیے)
cat > gradle.properties << 'PROPS'
android.useAndroidX=true
android.enableJetifier=true
android.suppressUnsupportedCompileSdk=34
org.gradle.jvmargs=-Xmx1024m -XX:MaxMetaspaceSize=512m
PROPS

# README
cat > README.md << 'README'
# Business Finder App

## تفصیل
یہ اینڈرائیڈ ایپ گوگن میپس (OpenStreetMap) سے کاروباری ڈیٹا نکالتی ہے۔

## تنصیب
APK انسٹال کریں اور لائسنس کوڈ درج کریں۔

## انتباہ
ادائیگی کے بعد رقم واپس نہیں ہوگی۔
README

echo "✅ تمام فائلیں تیار ہیں۔ اب APK بنا رہا ہوں..."
./gradlew clean assembleRelease --no-daemon

echo "📱 APK تیار ہو چکی ہے۔ راستہ:"
echo "app/build/outputs/apk/release/app-release.apk"
