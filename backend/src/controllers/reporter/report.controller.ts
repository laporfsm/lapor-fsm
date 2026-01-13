import { Elysia, t } from "elysia";

export const reportController = new Elysia({ prefix: '/reports' })
  // Get Public Feed (Mock)
  .get('/', () => {
    return {
      status: 'success',
      data: [
        {
          id: 1,
          category: 'Infrastruktur',
          title: 'AC Mati di Gedung E101',
          location: 'Gedung E, Lantai 1',
          timestamp: new Date().toISOString(),
          status: 'Pending'
        }
      ]
    };
  })
  
  // Submit New Report
  .post('/', ({ body }) => {
    // TODO: Save to Database (PostgreSQL)
    console.log("New Report Received:", body);
    
    return {
      status: 'created',
      message: 'Laporan berhasil dikirim, teknisi akan segera meluncur!',
      data: body
    };
  }, {
    body: t.Object({
      title: t.String(),
      description: t.String(),
      category: t.String(), // 'Medis', 'Keamanan', 'Infrastruktur', 'K3'
      location: t.Object({
        latitude: t.Number(),
        longitude: t.Number(),
        detail: t.Optional(t.String())
      })
    })
  });
