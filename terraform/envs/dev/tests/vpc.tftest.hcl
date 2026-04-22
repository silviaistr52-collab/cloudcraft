run "vpc_has_correct_cidr" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR must be 10.0.0.0/16"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "VPC must have DNS hostnames enabled"
  }
}

run "subnets_have_correct_cidrs" {
  command = plan

  assert {
    condition     = aws_subnet.public.cidr_block == "10.0.1.0/24"
    error_message = "Public subnet CIDR must be 10.0.1.0/24"
  }

  assert {
    condition     = aws_subnet.private.cidr_block == "10.0.2.0/24"
    error_message = "Private subnet CIDR must be 10.0.2.0/24"
  }
}

run "public_subnet_has_public_ip" {
  command = plan

  assert {
    condition = aws_subnet.public.map_public_ip_on_launch == false
    error_message = "Public subnet must not auto-assign public IPs"
  }
}
