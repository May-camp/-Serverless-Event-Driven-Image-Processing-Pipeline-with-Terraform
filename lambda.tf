resource "random_id" "bucket_suffix" {
   byte_length = 8
}

resource "aws_s3_bucket" "source_bucket" {
   bucket = "my-source-image-${random_id.bucket_suffix.hex}"
   force_destroy = true
}

resource "aws_s3_bucket" "dest_bucket" {
   bucket = "my-destination-image-${random_id.bucket_suffix.hex}"
   force_destroy = true
}

resource "null_resource" "build_pillow_layer" {
    provisioner "local-exec" {
        command = <<EOT
      mkdir -p ./python
      pip install --platform manylinux2014_x86_64 --target=./python --implementation cp --python-version 3.12 --only-binary=:all: --upgrade pillow
      zip -r pillow_layer.zip ./python
      rm -rf ./python
    EOT
    }
}

resource "aws_lambda_layer_version" "pillow_layer" {
   depends_on = [null_resource.build_pillow_layer]
   layer_name = "pillow_image_processing_layer"
   filename   = "pillow_layer.zip"
   compatible_runtimes = ["python3.12"]
}

resource "aws_iam_role" "lambda_role" {
   name = "lambda_execution_role"
   assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
         {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
               Service = "lambda.amazonaws.com"
            }
         }
      ]
   })
}

resource "aws_iam_policy" "lambda_s3_policy" {
   name = "lambda_execution_role"
   policy = jsonencode({
        Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"] # <-- S3 ထဲက ပုံလှမ်းယူခွင့်
        Resource = ["${aws_s3_bucket.source_bucket.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"] # <-- S3 ထဲ ပုံပြန်သိမ်းခွင့်
        Resource = ["${aws_s3_bucket.dest_bucket.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = [                # <-- စက်ရုပ် မှတ်တမ်းရေးခွင့်
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
   policy_arn = aws_iam_policy.lambda_s3_policy.arn
   role    = aws_iam_role.lambda_role.name
}

resource "aws_lambda_function" "processor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "example_lambda_function"
  role          = aws_iam_role.lambda_role.arn
  handler       =  "lambda_function.lambda_handler"
    runtime       = "python3.12"
    timeout       = 30
    layers        = [aws_lambda_layer_version.pillow_layer.arn]
    memory_size   = 128
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.dest_bucket.bucket
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFroms3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
    depends_on = [aws_lambda_permission.allow_s3]
  bucket = aws_s3_bucket.source_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  
}