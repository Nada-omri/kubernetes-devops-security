# kubesec-scan.ps1

# Using KubeSec v2 API
$kubeFile = "C:\ProgramData\Jenkins\.jenkins\workspace\devsecops-numeric-application\k8s_deployment_service.yaml"
$scanResult = Invoke-RestMethod -Uri "https://v2.kubesec.io/scan" -Method Post -InFile $kubeFile
$scanMessage = $scanResult[0].message
$scanScore = $scanResult[0].score

# Process the KubeSec scan result
if ($scanScore -ge 5) {
    Write-Host "Score is $scanScore"
    Write-Host "Kubesec Scan: $scanMessage"
} else {
    Write-Host "Score is $scanScore, which is less than or equal to 5."
    Write-Host "Scanning Kubernetes Resource has Failed"
    exit 1
}
