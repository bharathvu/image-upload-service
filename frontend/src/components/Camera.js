import React, { useRef, useState, useCallback, useEffect } from 'react';
import { uploadImage, uploadVideo } from '../services/api';

const Camera = ({ onUploadSuccess }) => {
  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const mediaRecorderRef = useRef(null);
  const chunksRef = useRef([]);
  
  const [stream, setStream] = useState(null);
  const [mode, setMode] = useState('photo'); // 'photo' or 'video'
  const [isRecording, setIsRecording] = useState(false);
  const [capturedImage, setCapturedImage] = useState(null);
  const [recordedVideo, setRecordedVideo] = useState(null);
  const [status, setStatus] = useState({ type: '', message: '' });
  const [isUploading, setIsUploading] = useState(false);
  const [cameraActive, setCameraActive] = useState(false);

  const startCamera = useCallback(async () => {
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: { 
          width: { ideal: 1280 },
          height: { ideal: 720 },
          facingMode: 'user'
        },
        audio: mode === 'video'
      });
      
      setStream(mediaStream);
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
      }
      setCameraActive(true);
      setStatus({ type: '', message: '' });
    } catch (err) {
      console.error('Error accessing camera:', err);
      setStatus({ 
        type: 'error', 
        message: 'Unable to access camera. Please ensure camera permissions are granted.' 
      });
    }
  }, [mode]);

  const stopCamera = useCallback(() => {
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      setStream(null);
    }
    setCameraActive(false);
    setCapturedImage(null);
    setRecordedVideo(null);
  }, [stream]);

  useEffect(() => {
    return () => {
      if (stream) {
        stream.getTracks().forEach(track => track.stop());
      }
    };
  }, [stream]);

  const handleModeChange = (newMode) => {
    if (isRecording) return;
    setMode(newMode);
    setCapturedImage(null);
    setRecordedVideo(null);
    if (cameraActive) {
      stopCamera();
    }
  };

  const capturePhoto = () => {
    if (!videoRef.current || !canvasRef.current) return;
    
    const video = videoRef.current;
    const canvas = canvasRef.current;
    
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    
    const ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0);
    
    const imageDataUrl = canvas.toDataURL('image/jpeg', 0.9);
    setCapturedImage(imageDataUrl);
    setStatus({ type: 'info', message: 'Photo captured! Click Upload to save.' });
  };

  const startRecording = () => {
    if (!stream) return;
    
    chunksRef.current = [];
    const options = { mimeType: 'video/webm;codecs=vp9' };
    
    try {
      mediaRecorderRef.current = new MediaRecorder(stream, options);
    } catch (e) {
      // Fallback to default codec
      mediaRecorderRef.current = new MediaRecorder(stream);
    }
    
    mediaRecorderRef.current.ondataavailable = (event) => {
      if (event.data.size > 0) {
        chunksRef.current.push(event.data);
      }
    };
    
    mediaRecorderRef.current.onstop = () => {
      const blob = new Blob(chunksRef.current, { type: 'video/webm' });
      const videoUrl = URL.createObjectURL(blob);
      setRecordedVideo({ url: videoUrl, blob });
      setStatus({ type: 'info', message: 'Video recorded! Click Upload to save.' });
    };
    
    mediaRecorderRef.current.start();
    setIsRecording(true);
    setStatus({ type: '', message: '' });
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      setIsRecording(false);
    }
  };

  const retake = () => {
    setCapturedImage(null);
    setRecordedVideo(null);
    setStatus({ type: '', message: '' });
  };

  const handleUpload = async () => {
    setIsUploading(true);
    setStatus({ type: 'info', message: 'Uploading...' });
    
    try {
      if (mode === 'photo' && capturedImage) {
        // Convert base64 to blob
        const response = await fetch(capturedImage);
        const blob = await response.blob();
        const result = await uploadImage(blob, `photo_${Date.now()}.jpg`);
        
        if (result.success) {
          setStatus({ type: 'success', message: 'Photo uploaded successfully!' });
          setCapturedImage(null);
          if (onUploadSuccess) onUploadSuccess();
        } else {
          setStatus({ type: 'error', message: result.message || 'Upload failed' });
        }
      } else if (mode === 'video' && recordedVideo) {
        const result = await uploadVideo(recordedVideo.blob, `video_${Date.now()}.webm`);
        
        if (result.success) {
          setStatus({ type: 'success', message: 'Video uploaded successfully!' });
          URL.revokeObjectURL(recordedVideo.url);
          setRecordedVideo(null);
          if (onUploadSuccess) onUploadSuccess();
        } else {
          setStatus({ type: 'error', message: result.message || 'Upload failed' });
        }
      }
    } catch (err) {
      console.error('Upload error:', err);
      setStatus({ type: 'error', message: 'Upload failed. Please try again.' });
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="camera-container">
      <div className="mode-toggle">
        <button 
          className={`mode-button ${mode === 'photo' ? 'active' : ''}`}
          onClick={() => handleModeChange('photo')}
          disabled={isRecording}
        >
          📷 Photo
        </button>
        <button 
          className={`mode-button ${mode === 'video' ? 'active' : ''}`}
          onClick={() => handleModeChange('video')}
          disabled={isRecording}
        >
          🎥 Video
        </button>
      </div>

      {status.message && (
        <div className={`status-message ${status.type}`}>
          {status.message}
        </div>
      )}

      {!cameraActive && !capturedImage && !recordedVideo && (
        <button className="btn btn-primary" onClick={startCamera}>
          📹 Start Camera
        </button>
      )}

      {cameraActive && !capturedImage && !recordedVideo && (
        <>
          <video 
            ref={videoRef} 
            autoPlay 
            playsInline 
            muted 
            className="video-preview"
          />
          
          {isRecording && (
            <div className="recording-indicator">
              <span className="recording-dot"></span>
              Recording...
            </div>
          )}
          
          <div className="camera-controls">
            {mode === 'photo' ? (
              <button className="btn btn-primary" onClick={capturePhoto}>
                📸 Capture Photo
              </button>
            ) : (
              <>
                {!isRecording ? (
                  <button className="btn btn-danger" onClick={startRecording}>
                    🔴 Start Recording
                  </button>
                ) : (
                  <button className="btn btn-secondary" onClick={stopRecording}>
                    ⏹️ Stop Recording
                  </button>
                )}
              </>
            )}
            <button className="btn btn-secondary" onClick={stopCamera}>
              ❌ Stop Camera
            </button>
          </div>
        </>
      )}

      {capturedImage && (
        <>
          <img src={capturedImage} alt="Captured" className="captured-image" />
          <div className="camera-controls">
            <button className="btn btn-secondary" onClick={retake}>
              🔄 Retake
            </button>
            <button 
              className="btn btn-success" 
              onClick={handleUpload}
              disabled={isUploading}
            >
              {isUploading ? '⏳ Uploading...' : '☁️ Upload'}
            </button>
          </div>
        </>
      )}

      {recordedVideo && (
        <>
          <video 
            src={recordedVideo.url} 
            controls 
            className="video-preview"
          />
          <div className="camera-controls">
            <button className="btn btn-secondary" onClick={retake}>
              🔄 Record Again
            </button>
            <button 
              className="btn btn-success" 
              onClick={handleUpload}
              disabled={isUploading}
            >
              {isUploading ? '⏳ Uploading...' : '☁️ Upload'}
            </button>
          </div>
        </>
      )}

      <canvas ref={canvasRef} style={{ display: 'none' }} />
    </div>
  );
};

export default Camera;
