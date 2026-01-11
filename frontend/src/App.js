import React, { useState } from 'react';
import Camera from './components/Camera';
import Gallery from './components/Gallery';

function App() {
  const [activeTab, setActiveTab] = useState('capture');
  const [galleryKey, setGalleryKey] = useState(0);

  const handleUploadSuccess = () => {
    // Refresh gallery when a new upload is successful
    setGalleryKey(prev => prev + 1);
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>📸 Media Capture</h1>
        <p>Capture photos and record videos directly from your browser</p>
      </header>

      <div className="tabs">
        <button 
          className={`tab-button ${activeTab === 'capture' ? 'active' : ''}`}
          onClick={() => setActiveTab('capture')}
        >
          📷 Capture
        </button>
        <button 
          className={`tab-button ${activeTab === 'gallery' ? 'active' : ''}`}
          onClick={() => setActiveTab('gallery')}
        >
          📁 Gallery
        </button>
      </div>

      <main className="main-content">
        {activeTab === 'capture' ? (
          <Camera onUploadSuccess={handleUploadSuccess} />
        ) : (
          <Gallery key={galleryKey} />
        )}
      </main>
    </div>
  );
}

export default App;
