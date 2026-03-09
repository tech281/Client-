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
