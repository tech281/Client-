package com.example.businessfinder

data class SearchCriteria(
    val businessType: String,
    val country: String = "",
    val city: String = "",
    val area: String = ""
)
