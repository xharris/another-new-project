$YourDirToCompress="src/*"
$ZipFileResult="releases/win/blanke"
$DirToExclude=@("projects","modules","plugins","template")

Get-ChildItem $YourDirToCompress | 
           where { $_.Name -notin $DirToExclude} | 
              Compress-Archive -DestinationPath $ZipFileResult -Update