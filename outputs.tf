output "fileName" {
  value = module.local-file.file_name
}

output "larryName" {
  value = module.larry-file.file_name
}

output "larryFileResult" {
  value = module.echo-larry-result.stdout
}