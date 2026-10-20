from system import Package

PACKAGES = [Package('gh', winget='GitHub.cli', scope='machine'), Package(apt=('ca-certificates',))]
