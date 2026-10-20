import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/payment_api.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override State<PaymentScreen> createState() => _PaymentScreenState();
}
class _PaymentScreenState extends State<PaymentScreen> {
  String plan='month'; Map<String,dynamic>? config, order; List<dynamic> history=[]; bool busy=false; String? error;
  @override void initState(){super.initState();load();}
  Future<void> load() async {try {final data=await PaymentApi.config();final past=await PaymentApi.orders();if(mounted)setState((){config=data;history=past;});}catch(e){if(mounted)setState(()=>error='$e');}}
  Future<void> create() async {
    final email=context.read<AppState>().userEmail;
    if(email.isEmpty){setState(()=>error='Bạn cần đăng nhập trước khi mua.');return;}
    setState((){busy=true;error=null;});
    try{final data=await PaymentApi.create(plan);if(mounted)setState(()=>order=data);await load();}catch(e){if(mounted)setState(()=>error='$e');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> refresh() async {
    if(order==null)return;
    setState(()=>busy=true);
    try{final data=await PaymentApi.status(order!['id'] as String);
      if(mounted){setState(()=>order={...order!,...data});
        if(data['status']=='approved' && data['expiry_at']!=null){
          await context.read<AppState>().applyApprovedPro(DateTime.parse(data['expiry_at'] as String));
          await load();
        }
      }
    }catch(e){if(mounted)setState(()=>error='$e');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){
    final prices=config?['prices'] as Map<String,dynamic>?;
    return Scaffold(appBar:AppBar(title:const Text('Thanh toán Pro bằng QR')),
      body:ListView(padding:const EdgeInsets.all(20),children:[
        const Text('Chọn gói Pro',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        RadioListTile<String>(title:Text('1 tháng: ${prices?['month'] ?? '...'} VNĐ'),value:'month',groupValue:plan,onChanged:order==null?(v)=>setState(()=>plan=v!):null),
        RadioListTile<String>(title:Text('1 năm: ${prices?['year'] ?? '...'} VNĐ'),value:'year',groupValue:plan,onChanged:order==null?(v)=>setState(()=>plan=v!):null),
        if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
        if(order==null) ElevatedButton(onPressed:busy||config==null?null:create,child:const Text('Tạo mã QR chuyển khoản')),
        if(order!=null)...[
          const SizedBox(height:16),
          Text('Mã đơn: ${order!['id']}',style:const TextStyle(fontWeight:FontWeight.bold)),
          Image.network(order!['qr_url'] as String,height:260,errorBuilder:(_,__,___)=>const Text('Không tải được QR. Vui lòng kiểm tra mạng.')),
          SelectableText('Ngân hàng: ${order!['bank_id']}\nSố tài khoản: ${order!['bank_account']}\nChủ tài khoản: ${order!['bank_name']}\nSố tiền: ${order!['amount']} VNĐ\nNội dung: ${order!['transfer_content']}'),
          const SizedBox(height:12),
          Text('Trạng thái: ${order!['status']}'),
          const Text('Chuyển đúng số tiền và nội dung. Admin sẽ kiểm tra ngân hàng rồi duyệt thủ công. Nhấn kiểm tra sau khi đã chuyển. Không tự động kích hoạt Pro.'),
          ElevatedButton(onPressed:busy?null:refresh,child:const Text('Kiểm tra trạng thái duyệt')),
        ],
        const SizedBox(height:24),
        const Text('Lịch sử đơn hàng',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        for(final item in history) ListTile(
          title:Text('${item['plan']=='month'?'Gói tháng':'Gói năm'} · ${item['amount']} VNĐ'),
          subtitle:Text('${item['id']} · ${item['created_at']}'),
          trailing:Text('${item['status']}'),
          onTap:null,
        ),
      ]));
  }
}
