// frontend/src/App.js
import React, { useEffect, useState } from 'react';

function App() {
  const [msg, setMsg] = useState('Loading...');
  useEffect(() => {
    // In k8s, we will route /api traffic to the backend
    fetch('/api/message')
      .then(res => res.json())
      .then(data => setMsg(data.message))
      .catch(err => setMsg('Error connecting to backend'));
  }, []);
  return <div><h1>Frontend UI</h1><p>{msg}</p></div>;
}
export default App;