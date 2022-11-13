add-content -path C:\Users\smart\.ssh\config -value @'

Host ${hostname}
  HostName ${hostname}
  User  ${user}
  IdentityFile  ${identityfile}
'@