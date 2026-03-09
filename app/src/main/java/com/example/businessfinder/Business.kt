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
