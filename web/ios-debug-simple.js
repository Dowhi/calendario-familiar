// Sistema de diagnóstico iOS SIMPLIFICADO - Sin interceptar propiedades
(function() {
  'use strict';
  
  // Solo ejecutar si es iOS
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) || 
                (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  
  if (!isIOS) return;
  
  console.log('🔍 Sistema de diagnóstico iOS SIMPLIFICADO iniciado');
  
  // Almacenar logs para envío remoto
  const debugLogs = [];
  const startTime = Date.now();
  
  // Función para agregar log con timestamp
  function addDebugLog(level, message, data = null) {
    const timestamp = Date.now() - startTime;
    const logEntry = {
      timestamp: timestamp,
      level: level,
      message: message,
      data: data,
      userAgent: navigator.userAgent,
      url: window.location.href
    };
    
    debugLogs.push(logEntry);
    console.log(`[${timestamp}ms] ${level.toUpperCase()}: ${message}`, data || '');
    
    // Mostrar en pantalla para iPhone
    updateDebugDisplay(logEntry);
  }
  
  // Función para mostrar logs en pantalla
  function updateDebugDisplay(logEntry) {
    const debugContainer = document.getElementById('debug-container');
    if (!debugContainer) {
      // Crear contenedor de debug si no existe
      const container = document.createElement('div');
      container.id = 'debug-container';
      container.style.cssText = `
        position: fixed;
        top: 10px;
        right: 10px;
        background: rgba(0,0,0,0.8);
        color: white;
        padding: 10px;
        border-radius: 5px;
        font-size: 10px;
        max-width: 200px;
        max-height: 300px;
        overflow-y: auto;
        z-index: 10000;
        font-family: monospace;
      `;
      document.body.appendChild(container);
    }
    
    const container = document.getElementById('debug-container');
    const logElement = document.createElement('div');
    logElement.style.cssText = `
      margin: 2px 0;
      padding: 2px;
      border-left: 2px solid ${getLogColor(logEntry.level)};
      padding-left: 5px;
    `;
    logElement.textContent = `[${logEntry.timestamp}ms] ${logEntry.level}: ${logEntry.message}`;
    
    container.appendChild(logElement);
    
    // Mantener solo los últimos 10 logs
    while (container.children.length > 10) {
      container.removeChild(container.firstChild);
    }
    
    // Scroll al final
    container.scrollTop = container.scrollHeight;
  }
  
  function getLogColor(level) {
    switch(level) {
      case 'error': return '#ff4444';
      case 'warn': return '#ffaa00';
      case 'info': return '#44ff44';
      default: return '#4444ff';
    }
  }
  
  // Interceptar errores globales SIN modificar propiedades
  window.addEventListener('error', function(event) {
    addDebugLog('error', `Error global: ${event.message}`, {
      message: event.message,
      filename: event.filename,
      lineno: event.lineno,
      colno: event.colno,
      error: event.error ? event.error.toString() : 'No error object',
      stack: event.error ? event.error.stack : 'No stack trace'
    });
  });
  
  window.addEventListener('unhandledrejection', function(event) {
    addDebugLog('error', `Promise rechazada: ${event.reason}`, {
      reason: event.reason,
      promise: event.promise,
      stack: event.reason && event.reason.stack ? event.reason.stack : 'No stack trace'
    });
  });
  
  // Monitorear carga de scripts SIN interceptar
  const originalCreateElement = document.createElement;
  document.createElement = function(tagName) {
    const element = originalCreateElement.call(this, tagName);
    
    if (tagName.toLowerCase() === 'script') {
      element.addEventListener('load', function() {
        addDebugLog('info', `Script cargado: ${element.src || 'inline'}`);
      });
      
      element.addEventListener('error', function() {
        addDebugLog('error', `Error cargando script: ${element.src || 'inline'}`);
      });
    }
    
    return element;
  };
  
  // Exponer funciones globales para diagnóstico
  window.iOSDebug = {
    addLog: addDebugLog,
    getLogs: () => debugLogs,
    clearLogs: () => debugLogs.length = 0
  };
  
  // Log inicial
  addDebugLog('info', 'Sistema de diagnóstico iOS SIMPLIFICADO iniciado');
  addDebugLog('info', `User Agent: ${navigator.userAgent}`);
  addDebugLog('info', `URL: ${window.location.href}`);
  
  // Verificar capacidades del navegador
  addDebugLog('info', `WebAssembly soportado: ${typeof WebAssembly !== 'undefined'}`);
  addDebugLog('info', `Service Worker soportado: ${'serviceWorker' in navigator}`);
  addDebugLog('info', `IndexedDB soportado: ${'indexedDB' in window}`);
  addDebugLog('info', `LocalStorage soportado: ${typeof localStorage !== 'undefined'}`);
  
  // Verificar si estamos en modo privado
  try {
    localStorage.setItem('test', 'test');
    localStorage.removeItem('test');
    addDebugLog('info', 'LocalStorage funcional');
  } catch (e) {
    addDebugLog('warn', 'LocalStorage no funcional (modo privado?)', e.message);
  }
  
  // Timeout para detectar si Flutter nunca se carga
  setTimeout(() => {
    if (!window._flutter || !window._flutter.loader) {
      addDebugLog('error', 'Flutter no se cargó después de 10 segundos');
    }
  }, 10000);
  
  setTimeout(() => {
    if (!window.flutterInitialized) {
      addDebugLog('error', 'Flutter no se inicializó después de 20 segundos');
    }
  }, 20000);
  
})();






