import preferences from '@kit.ArkData';

const STORAGE_KEY = 'user_storage';
let storage: preferences.Preferences | null = null;

// 初始化存储
export async function initStorage(): Promise<void> {
  try {
    storage = await preferences.getPreferences(globalThis.context, STORAGE_KEY);
  } catch (err) {
    console.error(`Storage init failed: ${err.code}, ${err.message}`);
  }
}

// 保存数据
export async function saveData(key: string, value: preferences.ValueType): Promise<void> {
  if (!storage) await initStorage();
  await storage?.put(key, value);
  await storage?.flush();
}

// 读取数据
export async function getData(key: string, defaultValue: preferences.ValueType): Promise<preferences.ValueType> {
  if (!storage) await initStorage();
  return await storage?.get(key, defaultValue) ?? defaultValue;
}

// 删除数据
export async function deleteData(key: string): Promise<void> {
  if (!storage) await initStorage();
  await storage?.delete(key);
  await storage?.flush();
}