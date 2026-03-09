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
