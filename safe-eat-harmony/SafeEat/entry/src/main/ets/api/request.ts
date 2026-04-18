// 导入鸿蒙网络模块+工具类
import { http } from '@kit.NetworkKit';
import userStore from '../store/userStore';
import { showToast } from '@kit.ArkUI';

// 后端基础URL（替换为你的NestJS部署地址，本地调试用http://127.0.0.1:3000）
const BASE_URL = 'https://your-nestjs-server.com/api';
// 超时时间（10秒）
const TIME_OUT = 10000;

// 封装请求函数
export async function request<T>(options: {
  url: string;
  method: http.RequestMethod;
  data?: any;
  headers?: Record<string, string>;
}): Promise<T> {
  // 创建HTTP客户端
  const client = http.createHttp();
  // 拼接完整URL
  const requestUrl = `${BASE_URL}${options.url}`;
  // 合并请求头（默认JSON格式，注入Token）Ï
  const requestHeaders: Record<string, string> = {
    'Content-Type': 'application/json',
    ...options.headers
  };

  // 注入登录Token（从store获取）
  const token = userStore.getToken();
  if (token) {
    requestHeaders['Authorization'] = `Bearer ${token}`;
  }

  try {
    // 发送请求
    const response = await client.request(requestUrl, {
      method: options.method,
      header: requestHeaders,
      data: options.data,
      readTimeout: TIME_OUT,
      connectTimeout: TIME_OUT
    });

    // 处理响应状态码
    if (response.responseCode === 200) {
      // 解析响应数据（适配NestJS返回格式：{code:200,data:...,msg:...}）
      const result = JSON.parse(response.result as string) as {
        code: number;
        data: T;
        msg: string;
      };
      if (result.code === 200) {
        return result.data;
      } else {
        // 业务错误（如Token过期、参数错误）
        showToast({ message: result.msg || '请求失败' });
        throw new Error(result.msg || '业务错误');
      }
    } else if (response.responseCode === 401) {
      // Token过期/未登录：清除Token并跳转登录页
      userStore.clearToken();
      showToast({ message: '登录已过期，请重新登录' });
      // 鸿蒙路由跳转（需导入router）
      import router from '@ohos.router';
      router.replace({ url: 'pages/LoginPage' });
      throw new Error('登录过期');
    } else {
      // 其他HTTP错误（500/404等）
      showToast({ message: `请求失败：${response.responseCode}` });
      throw new Error(`HTTP状态码：${response.responseCode}`);
    }
  } catch (error) {
    // 网络异常（如断网、超时）
    showToast({ message: '网络连接异常，请检查网络' });
    throw error;
  } finally {
    // 销毁客户端（释放资源）
    client.destroy();
  }
}