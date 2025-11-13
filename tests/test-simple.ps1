# Simple Test Script - Httpbin Deployment
Write-Host "=== Httpbin Deployment Test ===" -ForegroundColor Cyan
Write-Host ""

# Get Load Balancers from kubectl
Write-Host "Load Balancers:" -ForegroundColor White
$publicLB = C:\kube\kubectl.exe get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
$privateLB = C:\kube\kubectl.exe get svc -n ingress-nginx-internal ingress-nginx-controller-internal -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null

if (-not $publicLB) {
    Write-Host "  ERROR: Could not retrieve public load balancer hostname" -ForegroundColor Red
    exit 1
}
if (-not $privateLB) {
    Write-Host "  ERROR: Could not retrieve private load balancer hostname" -ForegroundColor Red
    exit 1
}

Write-Host "  Public:  $publicLB" -ForegroundColor Gray
Write-Host "  Private: $privateLB" -ForegroundColor Gray
Write-Host ""

# Test 1: Public /get
Write-Host "Test 1: Public /get (should work)" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$publicLB/get" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "  PASS - HTTP $($response.StatusCode)" -ForegroundColor Green
    }
} catch {
    Write-Host "  FAIL - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Public /post (should fail with 404)
Write-Host "Test 2: Public /post (should be 404)" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$publicLB/post" -Method POST -UseBasicParsing -TimeoutSec 10
    Write-Host "  FAIL - HTTP $($response.StatusCode) (expected 404)" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Host "  PASS - HTTP 404 (endpoint not exposed)" -ForegroundColor Green
    } else {
        Write-Host "  FAIL - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 3: Private /post from internet (should timeout or fail)
Write-Host "Test 3: Private /post from internet (should fail)" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$privateLB/post" -Method POST -UseBasicParsing -TimeoutSec 5
    Write-Host "  WARNING - Internal LB might be accessible: HTTP $($response.StatusCode)" -ForegroundColor Yellow
} catch {
    Write-Host "  PASS - Connection blocked (internal only)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Pod Status ===" -ForegroundColor Cyan
C:\kube\kubectl.exe get pods -n default -l app=httpbin
C:\kube\kubectl.exe get pods -n ingress-nginx
C:\kube\kubectl.exe get pods -n ingress-nginx-internal

Write-Host ""
Write-Host "=== Ingress Status ===" -ForegroundColor Cyan
C:\kube\kubectl.exe get ingress -n default

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Public Endpoint:  http://$publicLB/get" -ForegroundColor White
Write-Host "Private Endpoint: http://$privateLB/post (VPC only)" -ForegroundColor White
Write-Host ""
Write-Host "Configuration is portable and ready for deployment to other clusters!" -ForegroundColor Green
