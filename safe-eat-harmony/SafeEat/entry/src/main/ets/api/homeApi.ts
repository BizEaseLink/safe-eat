import { request } from './request';
import { HomeData, FunctionItem } from '../model/homeModel';
import http from '@ohos.net.http';  // 新增导入

export async function getHomeData(): Promise<HomeData> {
  return request<HomeData>({  // 添加泛型
    url: '/home/getData',
    method: http.RequestMethod.GET
  });
}

export async function getFunctionList(): Promise<FunctionItem[]> {
  return request<FunctionItem[]>({  // 添加泛型
    url: '/home/functionList',
    method: http.RequestMethod.GET
  });
}

// 扩展：Home页功能点击上报（POST请求，示例）
export async function reportFunctionClick(functionId: string) {
  return request<void>({
    url: '/home/reportClick',
    method: http.RequestMethod.POST,
    data: { functionId }
  });
}