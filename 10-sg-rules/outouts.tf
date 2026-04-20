output "my_ipv4_address" {
  value = chomp(data.http.my_public_ip_v4.response_body)
}