
 data "aws_route53_zone" "zone" {
  name = "sandpit5.rapidai.com."  # Change this to your Route53 managed zone
}

resource "aws_route53_record" "cname_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "flyte"  # Replace with your desired subdomain
  type    = "CNAME"
  ttl     = 60  # Time to Live in seconds

  records = ["k8s-flyte-91c5752089-1140960138.us-west-2.elb.amazonaws.com"] #Once Flyte is deployed, you can change this with the ALB

  allow_overwrite = true
}
# Change domain_name to match the name you'll use to connect to Flyte
resource "aws_acm_certificate" "flyte_cert" {
  domain_name       = "flyte.sandpit5.rapidai.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

module "external_dns_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.11.2"

  role_name                     = "fthw-external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.zone.arn]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

resource "helm_release" "external_dns" {
  namespace = "kube-system"
  wait      = true
  timeout   = 600

  name = "external-dns"

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.12.1"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_dns_irsa_role.iam_role_arn
  }
}

output "aws_acm_certificate" {
  value = [aws_acm_certificate.flyte_cert.arn]

}