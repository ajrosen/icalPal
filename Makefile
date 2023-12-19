APP=icalPal
VERSION=1.1.4

GEM=$(APP)-$(VERSION).gem

$(GEM):
	gem build $(APP).gemspec -q

clean: uninstall
	rm -f $(GEM)

install: $(GEM)
	gem install --local $(GEM)

user-install: $(GEM)
	gem install --local --user-install $(GEM)

uninstall:
	-gem uninstall $(APP) -ax

push: $(GEM)
	gem push $(GEM)

fury: $(GEM)
	fury push $(GEM)
