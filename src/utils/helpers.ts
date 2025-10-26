export function generateId(length = 8): string {
  return Math.random().toString(36).substring(2, 2 + length);
}

export function currentTimestamp(): string {
  return new Date().toISOString();
}
