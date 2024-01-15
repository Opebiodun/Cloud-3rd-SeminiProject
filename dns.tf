resource "aws_route53_zone" "main" {
  name = "adopaserves.com"
}

resource "aws_route53_record" "terraform-test" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "terraform-test.adopaserves.com"
  type    = "A"
  alias {
    name                   = aws_elb.Altschool_elb.dns_name
    zone_id                = aws_elb.Altschool_elb.zone_id
    evaluate_target_health = true
  }
}




