export interface MarketplacePackage {
  id: string;
  manifest: string;
  flow: string;
  signature: string;
  publicKey: string;
  createdAt: string;
}

const packages = new Map<string, MarketplacePackage>();

export function putPackage(pkg: MarketplacePackage): void {
  packages.set(pkg.id, pkg);
}

export function getPackage(id: string): MarketplacePackage | undefined {
  return packages.get(id);
}

export function listPackages(): MarketplacePackage[] {
  return Array.from(packages.values());
}
