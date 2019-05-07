# OpenSSL Certificate Management

## Structure

### Organizations

The management is split across organizations.  The default, "Template", contains three folders: CA, Servers, Users.

### Certificate Authorities

- Root CA (0000)
- Issuing CA (0001 - 0099)
- Service CA (0100 - 0000)

For an organization, a root CA is needed.  This root certificate is the parent of the entire trust chain for the organization.  Issuing CA can either issue server and user certificate themselves, or issue CA certificates, like you can order a CA certificate from some of the larger certificate authorities to issue certificates within your organization for use with remote desktop, and the like.  Service CA cannot create certificate authorities, but can issue certificates, such that a remote desktop administrator can issue certificates for its users without compromizing the security of the web services certificate, and vice-versa.

### Server and User

Server certificates are not really different from user certificates, and a distinction is made here simply for convenience.  Server certificates can be certificates for any service that requires SSL and/or TLS encryption.

## Example

Our trust chain is going to be called RootCert.  RootCert is a new certifying authority, and their root certificate is going to be added to the Mozilla certificate authorities package, that is issued to every browser, and is ussed by almost all apps, and opensource software, and firmware out there.  So we are going to issue a Root CA certificate to RootCert, and the public key is going to be sent to Mozilla for inclusion (after they've completed their audit of our company, of course).

RootCert CA

RootCert now has the power to issue certificates to servers, but it wouldn't be a good idea to use that certificate for anything else than for the fact it's included in the Mozilla security package, so we are going to issue certificate authorities with our root CA certificate.  Here RootCert is going to create two CAs, RootCert Issuing CA, and RootCert Internal CA.  One will issue certificates for authorities that issue certificates to third party servers, the other is going to issue certificates for CAs that issue certificates that are in use by RootCert internally, such as by their remote desktop server.

RootCert Issuing CA
RootCert Internal CA

The following level is optional, the certificates that descent immediately from our Root CA certificate can be made terminal points of the trust chain, and so they cannot create certificate authorities of their own.  Your issuing CAs could be your Service CAs if you wanted, but creating Service CAs from Issuing CAs adds a layer of security, gives us more maneuvering room in the future, and allows us to use trust chains intelligently to create compartments, so it might be a good idea to stretch things a little, and this extra later.  For simplicity, however, and so the example doesn't end-up a use case, we are only going to descend into RootCert Issuing CA... any other CAs you create at this level would be identical, anyway.

From RootCert Issuing CA, we are going to create a terminal certificate authority, one that can only issue server, and user certificates.  A popular use is for web servers, and another is e-mail signature, so we are going to create the following terminal CA certificates:

RootCert Web Authority
RootCert User Authority

## Server Certificates


## User Certificates


## Trust Chains

The public certificate from RootCert Root CA, if added to a browser's certificate keychain, will recognize any certificate that descends from it, and this is a good thing if all you do is issue certificates for HTTP servers, but it would make certificates for one company's VPN compatible with another company's VPN, and essentially merge them if their servers have your root CA public key.  Here, again, we can see that adding another layer between Root and Service can be useful.  Even if the certifiates are used in a development environment, I still think it's a good excerise to maintain such a complex security infrastructure, and to try and "do it right".


