/*
  Safe-Eat Prototype API Layer
  用途：
  1. 给华为 AI 看页面该怎么请求后端。
  2. 给 ArkTS 转换时保留统一的方法名。
  3. 说明本地/沙盒历史记录应该长什么样。
*/

const API_BASE_URL = 'http://127.0.0.1:3000/api';
const APP_PREFIX = '/v1/safe-eat';

const toHeaders = (accessToken, extra = {}) => ({
  Authorization: accessToken ? `Bearer ${accessToken}` : '',
  ...extra,
});

export const SafeEatAPI = {
  sendSms(phone) {
    return fetch(`${API_BASE_URL}${APP_PREFIX}/auth/sms/send`, {
      method: 'POST',
      headers: toHeaders(null, { 'Content-Type': 'application/json' }),
      body: JSON.stringify({ phone }),
    }).then((response) => response.json());
  },

  login(phone, code) {
    return fetch(`${API_BASE_URL}${APP_PREFIX}/auth/login`, {
      method: 'POST',
      headers: toHeaders(null, { 'Content-Type': 'application/json' }),
      body: JSON.stringify({ phone, code }),
    }).then((response) => response.json());
  },

  getProfile(accessToken) {
    return fetch(`${API_BASE_URL}${APP_PREFIX}/me`, {
      headers: toHeaders(accessToken),
    }).then((response) => response.json());
  },

  updateHealthProfile(accessToken, payload) {
    return fetch(`${API_BASE_URL}${APP_PREFIX}/me/health-profile`, {
      method: 'PATCH',
      headers: toHeaders(accessToken, { 'Content-Type': 'application/json' }),
      body: JSON.stringify(payload),
    }).then((response) => response.json());
  },

  createRecognition(accessToken, imageFile) {
    const formData = new FormData();
    formData.append('image', imageFile);

    return fetch(`${API_BASE_URL}${APP_PREFIX}/recognitions`, {
      method: 'POST',
      headers: toHeaders(accessToken),
      body: formData,
    }).then((response) => response.json());
  },

  getRecognition(accessToken, recognitionId) {
    return fetch(`${API_BASE_URL}${APP_PREFIX}/recognitions/${recognitionId}`, {
      headers: toHeaders(accessToken),
    }).then((response) => response.json());
  },

  submitFeedback(accessToken, recognitionId, payload) {
    const formData = new FormData();
    if (payload.proposedName) {
      formData.append('proposedName', payload.proposedName);
    }
    if (payload.comment) {
      formData.append('comment', payload.comment);
    }
    if (payload.evidenceImage) {
      formData.append('evidenceImage', payload.evidenceImage);
    }

    return fetch(`${API_BASE_URL}${APP_PREFIX}/recognitions/${recognitionId}/feedback`, {
      method: 'POST',
      headers: toHeaders(accessToken),
      body: formData,
    }).then((response) => response.json());
  },

  getPlans(accessToken) {
    return fetch(`${API_BASE_URL}${APP_PREFIX}/membership/plans`, {
      headers: toHeaders(accessToken),
    }).then((response) => response.json());
  },

  createOrder(accessToken, planId, channel) {
    return fetch(`${API_BASE_URL}${APP_PREFIX}/orders`, {
      method: 'POST',
      headers: toHeaders(accessToken, { 'Content-Type': 'application/json' }),
      body: JSON.stringify({ planId, channel }),
    }).then((response) => response.json());
  },
};

export const SafeEatLocalHistory = {
  storageKey: 'safe-eat-local-history',

  schemaExample: {
    recognitionId: 'recognition-id',
    localImageUri: 'internal://safe-eat/history/2026-04-03/001.jpg',
    recognizedName: '面条',
    adviceLevel: 'caution',
    foodScore: 64,
    createdAt: '2026-04-03T15:20:00.000Z',
  },
};
