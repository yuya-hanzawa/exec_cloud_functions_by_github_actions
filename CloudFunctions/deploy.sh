gcloud functions deploy hello-world \
   --region asia-northeast1 \
   --no-allow-unauthenticated \
   --entry-point hello_http \
   --gen2 \
   --runtime python312 \
   --service-account sa-gcf-executor@hanzawa-yuya.iam.gserviceaccount.com \
   --trigger-http
