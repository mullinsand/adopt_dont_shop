class Pet < ApplicationRecord
  validates :name, presence: true
  validates :age, presence: true, numericality: true
  belongs_to :shelter
  has_many :pet_applications
  has_many :applications, through: :pet_applications

  scope :is_adoptable, -> (is_adoptable = true) {where(adoptable: is_adoptable)}
  scope :applications_status, -> (status = "Pending") {where("applications.status = ?", status)}
  scope :pets_status, -> {select('pet_applications.pet_status')}
  scope :apps_status, -> {select("applications.status as application_status")}

  def shelter_name
    shelter.name
  end

  def self.adoptable
    is_adoptable
  end

  def self.add_pet_status(params)
    select('pets.*', 'pet_applications.application_id as app_id').pets_status.joins(:pet_applications).distinct
  end

  def self.pending_apps
    joins(:applications, :shelter).select('shelters.*').where("applications.status = ?", "Pending").distinct.order("shelters.name")
  end

  def self.avg_age
    adoptable.average(:age).round(1)
  end

  def self.count_adoptable
    is_adoptable.count
  end

  def self.adopted_pet_count
    is_adoptable(false).count
  end

  def self.pet_app_pending(shelter_id)
    select("pets.name as pet_name", "pets.shelter_id as shelter_id", "applications.id as application_id").pets_status.apps_status.joins(:applications).applications_status.where("shelter_id = ?", shelter_id)
  end
end
