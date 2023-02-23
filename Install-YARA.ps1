# This script assumes Python 3 is already installed on the machine

# Download Yara and its dependencies
$yara_url = "https://github.com/VirusTotal/yara/archive/refs/tags/v4.2.0.zip"
$pefile_url = "https://github.com/erocarrera/pefile/archive/refs/tags/2021.5.24.zip"
$ssdeep_url = "https://github.com/ssdeep-project/ssdeep/releases/download/release-2.14.1/ssdeep-2.14.1-win64.zip"
$yara_rules_url = "https://github.com/Yara-Rules/rules/archive/master.zip"

$yara_zip = "yara.zip"
$pefile_zip = "pefile.zip"
$ssdeep_zip = "ssdeep.zip"
$yara_rules_zip = "yara_rules.zip"

Invoke-WebRequest -Uri $yara_url -OutFile $yara_zip
Invoke-WebRequest -Uri $pefile_url -OutFile $pefile_zip
Invoke-WebRequest -Uri $ssdeep_url -OutFile $ssdeep_zip
Invoke-WebRequest -Uri $yara_rules_url -OutFile $yara_rules_zip

# Extract files
Expand-Archive -LiteralPath $yara_zip -DestinationPath "C:\Program Files"
Expand-Archive -LiteralPath $pefile_zip -DestinationPath "C:\Program Files"
Expand-Archive -LiteralPath $ssdeep_zip -DestinationPath "C:\Program Files"
Expand-Archive -LiteralPath $yara_rules_zip -DestinationPath "C:\Program Files"

# Install Yara
cd "C:\Program Files\yara-4.2.0"
.\bootstrap.bat
.\configure --enable-cuckoo --enable-magic --enable-dotnet
make
make install

# Install Python modules
cd "C:\Program Files\pefile-2021.5.24"
python setup.py install
cd "C:\Program Files\ssdeep-2.14.1-win64"
python setup.py install

# Install Yara rules
cd "C:\Program Files\rules-master"
.\install.bat

# Clean up
Remove-Item $yara_zip
Remove-Item $pefile_zip
Remove-Item $ssdeep_zip
Remove-Item $yara_rules_zip
