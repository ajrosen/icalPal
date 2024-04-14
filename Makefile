APP=icalPal
VERSION=1.2.1

GEM=$(APP)-$(VERSION).gem

$(GEM):
	gem build $(APP).gemspec -q

clean: uninstall
	rm -f $(GEM)

install: $(GEM)
	gem install $(GEM)

user-install: $(GEM)
	gem install --user-install $(GEM)

uninstall:
	-gem uninstall $(APP) -ax

push: $(GEM)
	gem push $(GEM)

fury: $(GEM)
	fury push $(GEM)
