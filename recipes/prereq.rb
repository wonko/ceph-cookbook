# get a newer kernel
apt_repository "squeeze-backports" do
  uri "http://backports.debian.org/debian-backports"
  distribution "squeeze-backports"
  components ["main"]
  action :add
end

# package "..." do options "-t squeeze-backports" end fails to select the correct kernel
execute "install newer kernel image from backports" do
  command "apt-get install -y -t squeeze-backports linux-image-2.6.39-bpo.2-amd64"
  not_if "dpkg-query -W linux-image-2.6-amd64 | grep 2.6.39"
end

