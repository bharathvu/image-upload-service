import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const uploadImage = async (blob, filename = 'capture.jpg') => {
  const formData = new FormData();
  formData.append('file', blob, filename);
  
  const response = await api.post('/media/upload/image', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response.data;
};

export const uploadVideo = async (blob, filename = 'recording.webm') => {
  const formData = new FormData();
  formData.append('file', blob, filename);
  
  const response = await api.post('/media/upload/video', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response.data;
};

export const getAllMedia = async () => {
  const response = await api.get('/media');
  return response.data;
};

export const getImages = async () => {
  const response = await api.get('/media/images');
  return response.data;
};

export const getVideos = async () => {
  const response = await api.get('/media/videos');
  return response.data;
};

export const deleteMedia = async (id) => {
  const response = await api.delete(`/media/${id}`);
  return response.data;
};

export const getMediaUrl = (id) => {
  return `${API_BASE_URL}/media/${id}/download`;
};

export default api;
