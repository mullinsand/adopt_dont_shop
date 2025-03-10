require 'rails_helper'

RSpec.describe 'the admin application show' do
  before :each do
    @app1 = Application.create!(fname: 'John', lname: 'Smithson', street_address: '12324 Turing Blvd.', city: 'Dtown', state: 'CO', zip_code: 12345, good_home_argument: 'Because reasons', status: "Pending" )

    @app2 = Application.create!(fname: 'John', lname: 'Smith', street_address: '1234 Turig Blvd.', city: 'Ttown', state: 'CO', zip_code: 12345, good_home_argument: 'Because reasonsable', status: "Pending" )
    @shelter1 = Shelter.create!(foster_program: true, name: 'Happy Shelter', city: 'Dmetro', rank: 3 )

    @pet1 = Pet.create!(adoptable: true, age: 5, breed: 'dog', name: 'Roofus', shelter_id: @shelter1.id)
    @pet2 = Pet.create!(adoptable: true, age: 12, breed: 'cat', name: 'Nacho', shelter_id: @shelter1.id)
    @pet3 = Pet.create!(adoptable: false, age: 8, breed: 'bird', name: 'Big', shelter_id: @shelter1.id)

    @shelter2 = Shelter.create!(name: 'Aurora shelter', city: 'Aurora, CO', foster_program: false, rank: 9)

    @pet4 = Pet.create!(adoptable: true, age: 1, breed: 'sphynx', name: 'Lucille Bald', shelter_id: @shelter2.id)
    @pet5 = Pet.create!(adoptable: true, age: 3, breed: 'doberman', name: 'Lobster', shelter_id: @shelter2.id)

    @app1.pets << @pet4 
    @app1.pets << @pet1 
    @app1.pets << @pet5
    @app2.pets << @pet1 
    @app2.pets << @pet5
  end

  describe 'As an admin' do
    describe 'visit /admin/application/:id' do
      it 'for every pet on app there is a button to approve adoption of specific pet' do
        visit "/admin/applications/#{@app1.id}"

        @app1.pets.each do |pet|
          within "#pet_#{pet.id}" do
            expect(page).to have_button("Approve #{pet.name} Adoption")
          end
        end
      end

      it 'when adoption approved is clicked taken back to admin/app/:id' do
        visit "/admin/applications/#{@app1.id}"

        click_button "Approve #{@pet4.name} Adoption"

        expect(current_path).to eq("/admin/applications/#{@app1.id}")
      end

      it "when adoption approved is clicked do not see button instead show 'approved'" do
        visit "/admin/applications/#{@app1.id}"

        click_button "Approve #{@pet4.name} Adoption"

        within "#pet_#{@pet4.id}" do
          expect(page).to have_content("Adoption Approved")
          expect(page).to_not have_button("Approve #{@pet4.name} Adoption")
          expect(page).to_not have_button("Reject #{@pet4.name} Adoption")
        end
      end

      it 'for every pet on app there is a button to reject adoption of specific pet' do
        visit "/admin/applications/#{@app1.id}"

        @app1.pets.each do |pet|
          within "#pet_#{pet.id}" do
            expect(page).to have_button("Reject #{pet.name} Adoption")
          end
        end
      end

      it 'when adoption rejected is clicked taken back to admin/app/:id' do
        visit "/admin/applications/#{@app1.id}"

        click_button "Reject #{@pet4.name} Adoption"

        expect(current_path).to eq("/admin/applications/#{@app1.id}")
      end

      it "when adoption rejected is clicked do not see button instead show 'rejected'" do
        visit "/admin/applications/#{@app1.id}"

        click_button "Reject #{@pet4.name} Adoption"

        within "#pet_#{@pet4.id}" do
          expect(page).to have_content("Adoption Rejected")
          expect(page).to_not have_content("Adoption Approved")
          expect(page).to_not have_button("Reject #{@pet4.name} Adoption")
          expect(page).to_not have_button("Accept #{@pet4.name} Adoption")
        end
      end
    end

    describe 'when two apps have the same pet' do
      describe 'when I visit the admin show page for the first one and approve/reject and visit second app' do
        it 'I do not see accepted/rejected, instead there are buttons!' do
          visit "/admin/applications/#{@app2.id}"

          click_button "Approve #{@pet1.name} Adoption"
          click_button "Reject #{@pet5.name} Adoption"

          visit "/admin/applications/#{@app1.id}"

          within "#pet_#{@pet1.id}" do
            expect(page).to_not have_content("Adoption Approved")
            expect(page).to_not have_content("Adoption Rejected")
            expect(page).to have_button("Approve #{@pet1.name} Adoption")
            expect(page).to have_button("Reject #{@pet1.name} Adoption")
          end

          within "#pet_#{@pet5.id}" do
            expect(page).to_not have_content("Adoption Approved")
            expect(page).to_not have_content("Adoption Rejected")
            expect(page).to have_button("Approve #{@pet5.name} Adoption")
            expect(page).to have_button("Reject #{@pet5.name} Adoption")
          end
        end
      end
    end

    describe 'when all pets are approved for an application' do
      it 'reloads the admin app show page where the app status has changed to approved' do
        visit "/admin/applications/#{@app2.id}"

        within "#application_#{@app2.id}" do
          expect(page).to have_content("Pending")
          expect(page).to_not have_content("Accepted")
        end

        click_button "Approve #{@pet1.name} Adoption"
        click_button "Approve #{@pet5.name} Adoption"

        within "#application_#{@app2.id}" do
          expect(page).to_not have_content("Pending")
          expect(page).to have_content("Accepted")
        end
      end
    end

    describe 'when one or more pets are rejected and the rest are approved for an application' do
      it 'reloads the admin app show page where the app status has changed to rejected' do
        visit "/admin/applications/#{@app2.id}"

        within "#application_#{@app2.id}" do
          expect(page).to have_content("Pending")
          expect(page).to_not have_content("Rejected")
        end

        click_button "Reject #{@pet1.name} Adoption"
        click_button "Approve #{@pet5.name} Adoption"

        within "#application_#{@app2.id}" do
          expect(page).to_not have_content("Pending")
          expect(page).to have_content("Rejected")
        end
      end
    end

    describe 'when all pets are approved for an application' do
      it 'visiting show page for each pets shows they are no longer adoptable' do
        visit "/admin/applications/#{@app2.id}"

        click_button "Approve #{@pet1.name} Adoption"
        click_button "Approve #{@pet5.name} Adoption"

        within "#application_#{@app2.id}" do
          expect(page).to have_content("Accepted")
        end

        visit "/pets/#{@pet1.id}"

        within "#adoptable" do
          expect(page).to have_content("false")
        end 

        visit "/pets/#{@pet5.id}"

        within "#adoptable" do
          expect(page).to have_content("false")
        end
      end
    end

    describe 'a pet with one pending application and one approved application' do
      it 'when I visit the pending application, I do not see a button to approve that pet' do
        visit "/admin/applications/#{@app2.id}"

        click_button "Approve #{@pet1.name} Adoption"
        click_button "Approve #{@pet5.name} Adoption"

        visit "/admin/applications/#{@app1.id}"

        within "#pet_#{@pet1.id}" do
          expect(page).to_not have_button("Approve #{@pet1.name} Adoption")
          expect(page).to have_button("Reject #{@pet1.name} Adoption")
        end

        within "#pet_#{@pet5.id}" do
          expect(page).to_not have_button("Approve #{@pet5.name} Adoption")
          expect(page).to have_button("Reject #{@pet5.name} Adoption")
        end
      end

      it 'when I visit the pending app, I do see a message that pet has been approved and a reject button' do
        visit "/admin/applications/#{@app2.id}"

        click_button "Approve #{@pet1.name} Adoption"
        click_button "Approve #{@pet5.name} Adoption"

        visit "/admin/applications/#{@app1.id}"

        within "#pet_#{@pet1.id}" do
          expect(page).to_not have_button("Approve #{@pet1.name} Adoption")
          expect(page).to have_content("*Already approved for adoption*")
          expect(page).to have_button("Reject #{@pet1.name} Adoption")
        end

        within "#pet_#{@pet5.id}" do
          expect(page).to_not have_button("Approve #{@pet5.name} Adoption")
          expect(page).to have_content("*Already approved for adoption*")
          expect(page).to have_button("Reject #{@pet5.name} Adoption")
        end
      end
    end
  end
end