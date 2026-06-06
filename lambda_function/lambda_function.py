import os
import boto3
from PIL import Image
import io

# S3 သိုလှောင်ရုံနဲ့ အလုပ်လုပ်ဖို့ ဖုန်းလိုင်းဖွင့်လိုက်ခြင်း
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Terraform က လှမ်းပေးမယ့် ပုံအသစ်သိမ်းမယ့် သေတ္တာ (Destination Bucket) နာမည်ကို ယူခြင်း
    DEST_BUCKET = os.environ['DEST_BUCKET']
    
    # ရောက်လာတဲ့ AWS စာအိတ်ကို အဆင့်ဆင့် ဖောက်ဖတ်ခြင်း
    for record in event['Records']:
        source_bucket = record['s3']['bucket']['name']
        image_key = record['s3']['object']['key']
        
        print(f"ပုံအသစ်တစ်ခု တွေ့ရှိပါပြီ: s3://{source_bucket}/{image_key}")
        
        try:
            # ၁။ S3 ထဲကနေ ဓာတ်ပုံရဲ့ raw dataBytes ကို လှမ်းယူခြင်း
            response = s3_client.get_object(Bucket=source_bucket, Key=image_key)
            image_content = response['Body'].read() # <--- ['Body'].read() ကို မမေ့နဲ့နော်
            
            # ၂။ ရလာတဲ့ raw data ကို Pillow သုံးပြီး ပုံအဖြစ် ဖွင့်ခြင်း
            image = Image.open(io.BytesIO(image_content))
            
            # ၃။ PNG ဖိုင်တွေရဲ့ background အလင်းပေါက်ကို JPEG ပြောင်းလို့ရအောင် အရောင်ညှိခြင်း
            if image.mode in ('RGBA', 'LA', 'P'):
                image = image.convert('RGB')
                
            # ၄။ မင်း Local မှာ အောင်မြင်အောင် စမ်းခဲ့တဲ့အတိုင်း 300x300 ချုံ့ခြင်း
            image.thumbnail((300, 300))
            
            # ၅။ RAM ပေါ်မှာ ယာယီစာအုပ် (Buffer) ထဲ သိမ်းခြင်း
            buffer = io.BytesIO()
            image.save(buffer, format="JPEG")
            buffer.seek(0) # <--- စာဖတ်ခေါင်းကို အစဆုံး ပြန်ရွှေ့ပေးခြင်း
            
            # ၆။ ပုံသေးလေးကို Destination Bucket ရဲ့ thumbnails/ ဆိုတဲ့ folder ထဲ သွားသိမ်းခြင်း
            destination_key = f"thumbnails/{image_key}"
            s3_client.put_object(
                Bucket=DEST_BUCKET,
                Key=destination_key,
                Body=buffer,
                ContentType='image/jpeg'
            )
            print(f"ပုံသေးလေးကို ဤနေရာသို့ အောင်မြင်စွာ ပို့ဆောင်ပြီးပါပြီ: s3://{DEST_BUCKET}/{destination_key}")
            
        except Exception as e:
            print(f"အမှားအယွင်း ဖြစ်ပေါ်ခဲ့ပါတယ်: {str(e)}")
            raise e

    return {"statusCode": 200, "body": "Processing Complete"}