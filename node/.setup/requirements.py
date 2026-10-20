from system import Package

MINIMUM = (22, 19, 0)
PACKAGES = [Package('node', winget='OpenJS.NodeJS.LTS', scope='machine', minimum=MINIMUM),
            Package(apt=('ca-certificates', 'curl', 'gnupg'))]
