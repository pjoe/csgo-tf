variable "region" {
  default = "us-east-1"
}

variable "server" {
  type = "map"

  default = {
    name          = "CS:GO Server"
    password      = ""
    rcon_password = "rcon"
    gslt          = ""
  }
}

variable "ami" {
  default = "ami-74afe70e"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "dns_zone" {
  default = "wyrmgard.com"
}

provider "aws" {
  region = "${var.region}"
}

data "aws_route53_zone" "csgo" {
  name = "${var.dns_zone}."
}

data "template_file" "start" {
  template = "${file("${path.module}/start.sh")}"

  vars {
    gslt = "${var.server["gslt"]}"
  }
}

data "template_file" "autoexec" {
  template = "${file("${path.module}/autoexec.cfg")}"

  vars {
    name          = "${var.server["name"]}"
    password      = "${var.server["password"]}"
    rcon_password = "${var.server["rcon_password"]}"
  }
}

resource "aws_key_pair" "csgo" {
  key_name   = "csgo"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "csgo" {
  ami                    = "${var.ami}"
  instance_type          = "t2.small"
  vpc_security_group_ids = ["${aws_security_group.csgo.id}"]
  subnet_id              = "${aws_subnet.default.id}"
  key_name               = "${aws_key_pair.csgo.id}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = "50"
  }

  tags {
    Name = "csgo"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    content     = "${data.template_file.autoexec.rendered}"
    destination = "/home/ubuntu/csgo-ds/csgo/cfg/autoexec.cfg"
  }

  provisioner "file" {
    content     = "${data.template_file.start.rendered}"
    destination = "/home/ubuntu/start.sh"
  }

  provisioner "file" {
    source      = "gamemodes_server.txt"
    destination = "/home/ubuntu/csgo-ds/csgo/gamemodes_server.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/start.sh",
    ]
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
