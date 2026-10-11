import { query } from "../db.js";
const letterStatus={draft:"Draf",diperiksa:"Sedang diperiksa",menunggu_approval:"Menunggu persetujuan",disetujui:"Disetujui, belum dikirim",ditolak:"Ditolak",dikirim:"Sah - sudah dikirim",diregistrasi:"Terdaftar",diteruskan:"Diteruskan",didisposisikan:"Didisposisikan",ditindaklanjuti:"Ditindaklanjuti",selesai:"Selesai"};
export async function verifyLetter(request,response,next){
 const rawInput=request.params.letterNumber.trim();
 if(!rawInput)return response.status(400).json({valid:false,message:"Nomor surat wajib diisi."});
 try{
  const result=await query(`SELECT letter_number AS "nomorSurat", subject AS "perihal", sender AS "instansiPenerbit",
   'STT Pekerjaan Umum' AS "unitBagian",letter_date AS "tanggalSurat",status::text AS "statusSurat",'Surat Masuk' AS "jenisSurat",
   NULL::text AS "penandatanganNama",NULL::text AS "penandatanganJabatan"
   FROM incoming_letters WHERE deleted_at IS NULL AND (letter_number ILIKE $1 OR agenda_number ILIKE $1)
   UNION ALL
   SELECT o.letter_number,o.subject,'STT Pekerjaan Umum',o.destination,o.letter_date,o.status::text,'Surat Keluar',u.full_name,u.position
   FROM outgoing_letters o LEFT JOIN users u ON u.id=o.approver_id
   WHERE o.deleted_at IS NULL AND o.letter_number ILIKE $1 LIMIT 1`,[`%${rawInput}%`]);
  if(!result.rows.length)return response.status(404).json({valid:false,message:"Surat dengan nomor tersebut tidak ditemukan di E-Office."});
  const letter=result.rows[0];const issued=letter.jenisSurat==="Surat Keluar"&&letter.statusSurat==="dikirim";
  const status=letterStatus[letter.statusSurat]||letter.statusSurat;
  const verificationStatus=letter.jenisSurat==="Surat Masuk"?`Tercatat sebagai surat masuk - ${status}`:status;
  const message=letter.jenisSurat==="Surat Masuk"?"Surat masuk tercatat di E-Office. Pencatatan ini bukan verifikasi tanda tangan penerbit.":issued?"Nomor surat terdaftar dan berstatus telah dikirim di E-Office.":`Nomor surat terdaftar di E-Office, tetapi statusnya: ${status}.`;
  response.json({valid:issued,message,data:{nomorSurat:letter.nomorSurat,perihal:letter.perihal,instansi:letter.instansiPenerbit,penerima:letter.unitBagian,penandatangan:{nama:letter.penandatanganNama||"",jabatan:letter.penandatanganJabatan||""},tanggalSurat:letter.tanggalSurat,jenisSurat:letter.jenisSurat,status:verificationStatus,statusVerifikasi:verificationStatus}});
 }catch(error){next(error);}
}
