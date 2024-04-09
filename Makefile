APP=$(shell ruby -e 'puts Gem::Specification::load("icalPal.gemspec").name')
VERSION=$(shell ruby -e 'puts Gem::Specification::load("icalPal.gemspec").version')

GEM=$(APP)-$(VERSION).gem

$(GEM):
	gem build $(APP).gemspec -q

clean:
	rm -fv *.gem

install: $(GEM)
	gem install --local $(GEM)

user-install: $(GEM)
	gem install --local --user-install $(GEM)

uninstall:
	-gem uninstall $(APP) -ax

rubygems: $(GEM)
	gem push $(GEM)

gemfury: $(GEM)
	fury push $(GEM)

publish:
	rubygems
	gemfury
