#Redshift cluster
resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier        = "tranx-redshift-cluster"
  database_name             = "sales_db"
  master_username           = aws_ssm_parameter.redshift_username.value
  master_password           = aws_ssm_parameter.redshift_password.value
  node_type                 = "ra3.large"
  cluster_type              = "multi-node"
  number_of_nodes           = 2
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift_subnet_group.name
  publicly_accessible       = true
  iam_roles                 = [aws_iam_role.redshift_role.arn]
  vpc_security_group_ids    = [aws_security_group.redshift_security_group.id]


}

# Redshift subnet group
resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name = "redshift-subnet-group"
  subnet_ids = [
    aws_subnet.public_subnet.id,
    aws_subnet.private_subnet.id
  ]
}

