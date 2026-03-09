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
