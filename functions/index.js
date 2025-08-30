const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require('firebase-functions/v2/firestore');

initializeApp();

exports.onEventCreated = onDocumentCreated('calendars/{calendarId}/events/{eventId}', async (event) => {
  const data = event.data.data();
  const calendarId = event.params.calendarId;
  const db = getFirestore();
  
  try {
    const calSnap = await db.doc(`calendars/${calendarId}`).get();
    const members = calSnap.get('members') || [];
    const recipients = members.filter(uid => uid !== data.ownerId);
    
    if (recipients.length === 0) return;
    
    const tokens = new Set();
    for (const uid of recipients) {
      const user = await db.doc(`users/${uid}`).get();
      const userTokens = user.get('deviceTokens') || [];
      userTokens.forEach(t => tokens.add(t));
    }
    
    if (tokens.size === 0) return;
    
    await getMessaging().sendEachForMulticast({
      tokens: Array.from(tokens),
      notification: { 
        title: 'Nuevo evento', 
        body: data.title 
      },
      data: { 
        calendarId, 
        eventId: event.params.eventId, 
        action: 'created' 
      }
    });
  } catch (error) {
    console.error('Error sending notification for event created:', error);
  }
});

exports.onEventUpdated = onDocumentUpdated('calendars/{calendarId}/events/{eventId}', async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const calendarId = event.params.calendarId;
  const db = getFirestore();
  
  try {
    const calSnap = await db.doc(`calendars/${calendarId}`).get();
    const members = calSnap.get('members') || [];
    const recipients = members.filter(uid => uid !== afterData.ownerId);
    
    if (recipients.length === 0) return;
    
    const tokens = new Set();
    for (const uid of recipients) {
      const user = await db.doc(`users/${uid}`).get();
      const userTokens = user.get('deviceTokens') || [];
      userTokens.forEach(t => tokens.add(t));
    }
    
    if (tokens.size === 0) return;
    
    await getMessaging().sendEachForMulticast({
      tokens: Array.from(tokens),
      notification: { 
        title: 'Evento actualizado', 
        body: afterData.title 
      },
      data: { 
        calendarId, 
        eventId: event.params.eventId, 
        action: 'updated' 
      }
    });
  } catch (error) {
    console.error('Error sending notification for event updated:', error);
  }
});

exports.onEventDeleted = onDocumentDeleted('calendars/{calendarId}/events/{eventId}', async (event) => {
  const data = event.data.data();
  const calendarId = event.params.calendarId;
  const db = getFirestore();
  
  try {
    const calSnap = await db.doc(`calendars/${calendarId}`).get();
    const members = calSnap.get('members') || [];
    const recipients = members.filter(uid => uid !== data.ownerId);
    
    if (recipients.length === 0) return;
    
    const tokens = new Set();
    for (const uid of recipients) {
      const user = await db.doc(`users/${uid}`).get();
      const userTokens = user.get('deviceTokens') || [];
      userTokens.forEach(t => tokens.add(t));
    }
    
    if (tokens.size === 0) return;
    
    await getMessaging().sendEachForMulticast({
      tokens: Array.from(tokens),
      notification: { 
        title: 'Evento eliminado', 
        body: data.title 
      },
      data: { 
        calendarId, 
        eventId: event.params.eventId, 
        action: 'deleted' 
      }
    });
  } catch (error) {
    console.error('Error sending notification for event deleted:', error);
  }
});




