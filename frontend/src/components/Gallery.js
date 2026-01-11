import React, { useState, useEffect, useCallback } from 'react';
import { getAllMedia, getImages, getVideos, deleteMedia, getMediaUrl } from '../services/api';

const Gallery = () => {
  const [mediaFiles, setMediaFiles] = useState([]);
  const [filter, setFilter] = useState('all'); // 'all', 'images', 'videos'
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchMedia = useCallback(async () => {
    setLoading(true);
    setError('');
    
    try {
      let data;
      switch (filter) {
        case 'images':
          data = await getImages();
          break;
        case 'videos':
          data = await getVideos();
          break;
        default:
          data = await getAllMedia();
      }
      setMediaFiles(data);
    } catch (err) {
      console.error('Error fetching media:', err);
      setError('Failed to load media files. Please ensure the backend server is running.');
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    fetchMedia();
  }, [fetchMedia]);

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this file?')) {
      return;
    }

    try {
      await deleteMedia(id);
      setMediaFiles(mediaFiles.filter(file => file.id !== id));
    } catch (err) {
      console.error('Error deleting file:', err);
      alert('Failed to delete file. Please try again.');
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="loading">
        <div className="spinner"></div>
      </div>
    );
  }

  return (
    <div className="gallery-container">
      <div className="gallery-header">
        <h2>📁 Media Gallery</h2>
        <div className="filter-buttons">
          <button 
            className={`filter-button ${filter === 'all' ? 'active' : ''}`}
            onClick={() => setFilter('all')}
          >
            All
          </button>
          <button 
            className={`filter-button ${filter === 'images' ? 'active' : ''}`}
            onClick={() => setFilter('images')}
          >
            Images
          </button>
          <button 
            className={`filter-button ${filter === 'videos' ? 'active' : ''}`}
            onClick={() => setFilter('videos')}
          >
            Videos
          </button>
        </div>
      </div>

      {error && (
        <div className="status-message error">
          {error}
        </div>
      )}

      {!error && mediaFiles.length === 0 && (
        <div className="empty-gallery">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
            <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V5h14v14zm-5-7l-3 3.72L9 13l-3 4h12l-4-5z"/>
          </svg>
          <h3>No media files yet</h3>
          <p>Capture some photos or videos to see them here!</p>
        </div>
      )}

      <div className="gallery-grid">
        {mediaFiles.map((file) => (
          <div key={file.id} className="gallery-item">
            {file.fileType === 'IMAGE' ? (
              <img 
                src={getMediaUrl(file.id)} 
                alt={file.originalFileName}
                className="gallery-item-preview"
              />
            ) : (
              <video 
                src={getMediaUrl(file.id)} 
                className="gallery-item-preview"
                controls
              />
            )}
            <div className="gallery-item-info">
              <h4 title={file.originalFileName}>{file.originalFileName}</h4>
              <p>
                {file.fileType === 'IMAGE' ? '📷' : '🎥'} {formatFileSize(file.fileSize)}
              </p>
              <p>{formatDate(file.uploadedAt)}</p>
            </div>
            <div className="gallery-item-actions">
              <a 
                href={getMediaUrl(file.id)} 
                target="_blank" 
                rel="noopener noreferrer"
                className="btn btn-primary"
              >
                👁️ View
              </a>
              <button 
                className="btn btn-danger"
                onClick={() => handleDelete(file.id)}
              >
                🗑️ Delete
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Gallery;
