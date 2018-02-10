provider "aws" {}

variable "ami" {
  default = "ami-74afe70e"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "dns_zone" {
  default = "wyrmgard.com"
}

data "aws_route53_zone" "csgo" {
  name = "${var.dns_zone}."
}

resource "aws_key_pair" "csgo" {
  key_name ="csgo"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "csgo" {
  ami           = "${var.ami}"
  instance_type = "t2.small"
  vpc_security_group_ids = ["${aws_security_group.csgo.id}"]
  subnet_id = "${aws_subnet.default.id}"
  key_name = "${aws_key_pair.csgo.id}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = "50"
  }

  tags {
    Name = "csgo"
  }
}

resource "aws_route53_record" "csgo" {
  zone_id = "${data.aws_route53_zone.csgo.zone_id}"
  name    = "csgo.${data.aws_route53_zone.csgo.name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.csgo.public_ip}"]
}

output "public_ip" {
    value = "${aws_instance.csgo.public_ip}"
}
