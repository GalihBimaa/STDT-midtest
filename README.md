# STDT-midtest
Ujian Tengah Semester Sistem Terdistribusi dan Terdesentralisasi
1. Penjelasan teorema **CAP** dan **BASE** beserta keterkaitan dan contoh.
2. Penjelasan hubungan **GraphQL** dengan komunikasi antar-proses + diagram.
## 1. Teorema CAP dan BASE (ringkas & contoh)

### Teorema CAP
- **C**onsistency: Semua node melihat data yang sama pada waktu yang sama. Setelah write berhasil, semua clients membaca value tersebut.
- **A**vailability: Setiap request (non-failing node) menerima respons (bukan error), walau datanya mungkin tidak paling baru.
- **P**artition tolerance: Sistem terus berfungsi meskipun terjadi network partition (pesan antar node terputus sebagian).

**Teorema CAP** menyatakan: dalam presence of partitions, sebuah sistem terdistribusi hanya bisa memuaskan **paling banyak dua** dari tiga properti ini — praktisnya: **Consistency** atau **Availability** harus dikorbankan ketika Partition terjadi.

**Contoh**:
- **Sistem bank** (transfer uang): lebih memilih **CP** — pada partition, sistem menolak transaksi agar menjaga konsistensi saldo (konsistensi prioritas).
- **Sistem caching read-heavy / sosial media**: lebih memilih **AP** — pada partition, tetap melayani pembacaan meski beberapa node belum ter-sinkron (availability prioritas).

### BASE (konsep untuk sistem 'eventual consistency')
- **B**asically Available: sistem menjamin respons (tidak selalu up-to-date).
- **S**oft state: state sistem dapat berubah secara bertahap tanpa input eksternal karena replikasi/propagasi.
- **E**ventually consistent: jika tidak ada update baru, semua replica akan konvergen ke state yang sama akhirnya.

**Keterkaitan CAP & BASE**
- BASE sering dipakai untuk mendesain sistem **AP** pada CAP: ketika Anda mengorbankan konsistensi langsung untuk availability, Anda biasanya menerapkan *eventual consistency* (BASE) supaya akhirny a data menjadi konsisten.
- Dengan kata lain: **AP (Cap) ↔ BASE (model)**. Sistem yang memilih availability selama partition akan menerapkan mekanisme BASE untuk menyelesaikan inkonsistensi belakangan (rekonsiliasi).

**Contoh yang pernah saya gunakan (ilustrasi sederhana)**
- Misal aplikasi komentar blog menggunakan cache & database:
  - Saat pengguna post komentar, komentar ditulis ke node lokal (tersedia cepat) → other nodes belum mempunyai komentar tersebut langsung (availability tinggi). Propagasi terjadi lewat queue/eventual sync → akhirnya semua node mempunyai komentar (eventual consistency). Ini adalah pola BASE (soft state + eventually consistent) yang cocok untuk AP pada CAP.

---

## 2. GraphQL dan komunikasi antar-proses (distributed IPC)

### Hubungan singkat
- **GraphQL** adalah lapisan query API yang memungkinkan client meminta persis data yang dibutuhkan. Dalam arsitektur terdistribusi, GraphQL biasanya berperan sebagai **gateway / aggregator** yang menerima request dan mengorkestrasi panggilan ke banyak layanan mikro (microservices) atau sumber data terdistribusi.
- Komunikasi antar-proses di sistem terdistribusi sering melibatkan:
  - **Synchronous HTTP/gRPC**: request/response langsung dari gateway ke microservice.
  - **Asynchronous messaging**: event bus, queue, pub/sub.
- GraphQL *tidak* menggantikan IPC; GraphQL memfasilitasi **koordinasi** panggilan IPC: dia mem-parallelize, batch, dan menggabungkan hasil dari banyak layanan menjadi satu response terstruktur.

### Kapan GraphQL memengaruhi IPC:
- **Batching & DataLoader**: mengurangi N+1 problem dengan menggabungkan banyak permintaan ke satu call.
- **Federation / Schema Stitching**: tiap layanan bertanggung jawab pada bagian schema, GraphQL gateway menggabungkan schema menjadi satu titik akses.
- **Orkestrasi Synchronous**: gateway memanggil banyak layanan (HTTP/gRPC) lalu menggabungkan hasilnya.
- **Trigger Asynchronous**: untuk operasi write, gateway bisa men-publish event ke message broker (RabbitMQ/Kafka), mengurangi latensi transaksi synchronous.

### Diagram
```mermaid
graph LR
    Client -->|GraphQL Query| GraphQL_Gateway

    %% Synchronous communication
    GraphQL_Gateway -->|HTTP gRPC sync| Auth_Service
    GraphQL_Gateway -->|HTTP gRPC sync| User_Service
    GraphQL_Gateway -->|HTTP gRPC sync| Product_Service

    %% Asynchronous communication
    GraphQL_Gateway -->|Publish Event| Message_Broker
    Message_Broker -->|Consume async| Analytics_Service
    Message_Broker -->|Consume async| Search_Indexer

    %% Databases
    Product_Service -->|DB Access| Product_DB
    User_Service -->|DB Access| User_DB
