output "workflow_name"    { value = aws_glue_workflow.main.name }
output "job1_name"        { value = aws_glue_job.job1_clean.name }
output "job2_name"        { value = aws_glue_job.job2_parquet.name }
output "glue_role_arn"    { value = aws_iam_role.glue.arn }