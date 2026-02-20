const packages = new Map();
export function putPackage(pkg) {
    packages.set(pkg.id, pkg);
}
export function getPackage(id) {
    return packages.get(id);
}
export function listPackages() {
    return Array.from(packages.values());
}
