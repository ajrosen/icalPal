APP=$(shell ruby -e 'require "./lib/version" and puts ICalPal::NAME')
VERSION=$(shell ruby -e 'require "./lib/version" and puts ICalPal::VERSION')

GEM=$(APP)-$(VERSION).gem

$(GEM): bin/icalpal lib/*.rb
	gem build $(APP).gemspec -q

clean:
	rm -fv *.gem

install: $(GEM)
	gem install $(GEM)

user-install: $(GEM)
	gem install --user-install $(GEM)

uninstall:
	-gem uninstall $(APP) -ax

rubygems: $(GEM)
	gem push $(GEM)

gemfury: $(GEM)
	fury push $(GEM)

publish: rubygems gemfury
