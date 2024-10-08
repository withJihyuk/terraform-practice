// 한개의 public subnet을 구축하는 코드입니다.
// nat gateway를 통해서 private subnet의 통신을 가능하게 하는 코드는 아직 학습중에 있습니다.
// 고정 아이피가 필요시엔, Elastic IP의 추가가 필요합니다.

resource "aws_vpc" "public_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "public_vpc"
  }
  // 가상 사설 클라우드로써 네트워크를 구성하는데 사용.
}

// 서브넷은? IP주소 범위로써의 구분이라고 보면 되는거고, VPC 아래 여러개 있어도 된다.
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.public_vpc.id
    cidr_block = "10.0.10.0/24" // VPC의 CIDR 범위 안에 있어야 함.
    map_public_ip_on_launch = true // 자동으로 아이피 할당.
    availability_zone = "ap-northeast-2a"
    tags = {
        Name = "public_subnet"
    }
}

resource "aws_internet_gateway" "public_igw" {
    vpc_id = aws_vpc.public_vpc.id
    tags = {
        Name = "public_igw"
    }
    // 외부로 통신하기 위한 게이트웨이 생성.
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.public_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.public_igw.id
    }
    tags = {
        name = "public_route_table"
    }
  // 해당 코드를 통해서 외부와 통신 하는 라우팅 규칙을 생성.
}

resource "aws_route_table_association" "route_table_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
    // 서브넷과 라우팅 테이블을 연결.  
}

resource "aws_security_group" "test_rule" {
  name_prefix = "test_rule" // production엔 이름 변경 필요
  vpc_id = aws_vpc.public_vpc.id
}

resource "aws_security_group_rule" "test_rule_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.test_rule.id
}

resource "aws_security_group_rule" "test_rule_web" {
  type        = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.test_rule.id
}

resource "aws_security_group_rule" "test_rule_all" {
  type             = "egress"
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  security_group_id = aws_security_group.test_rule.id
}
