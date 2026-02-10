# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Clear existing data (for development only)
puts "Clearing existing chains and checkpoints..."
Checkpoint.destroy_all
ChainParticipant.destroy_all
Chain.destroy_all
User.where("email LIKE '%@example.com'").destroy_all

# Create test users
users = {
  alice: User.find_or_create_by!(email: "alice@example.com") do |user|
    user.name = "Alice (Creator)"
    user.password = "password123"
    user.password_confirmation = "password123"
  end,
  bob: User.find_or_create_by!(email: "bob@example.com") do |user|
    user.name = "Bob (Lender)"
    user.password = "password123"
    user.password_confirmation = "password123"
  end,
  charlie: User.find_or_create_by!(email: "charlie@example.com") do |user|
    user.name = "Charlie (Borrower)"
    user.password = "password123"
    user.password_confirmation = "password123"
  end,
  diana: User.find_or_create_by!(email: "diana@example.com") do |user|
    user.name = "Diana (Viewer)"
    user.password = "password123"
    user.password_confirmation = "password123"
  end,
  eve: User.find_or_create_by!(email: "eve@example.com") do |user|
    user.name = "Eve (Multi-role)"
    user.password = "password123"
    user.password_confirmation = "password123"
  end
}

puts "Created #{users.size} users:"
users.each do |key, user|
  puts "  - #{user.email} (#{user.name})"
end

# Chain 1: Alice is creator and lender, Bob is borrower, Charlie is viewer
chain1 = Chain.find_or_create_by!(title: "Personal Loan - Alice to Bob") do |chain|
  chain.description = "Bob needed money for a new laptop"
  chain.creator = users[:alice]
  chain.lender = users[:alice]
  chain.borrower = users[:bob]
  chain.lent_money = 50000
  chain.outstanding = 50000  # Will be reduced by checkpoint
  chain.currency = "BDT"
  chain.status = :open
end

# Add participants for chain1
ChainParticipant.find_or_create_by!(chain: chain1, user: users[:alice]) do |cp|
  cp.role = :lender
end
ChainParticipant.find_or_create_by!(chain: chain1, user: users[:bob]) do |cp|
  cp.role = :borrower
end
ChainParticipant.find_or_create_by!(chain: chain1, user: users[:charlie]) do |cp|
  cp.role = :viewer
end

# Add some checkpoints for chain1
if chain1.checkpoints.empty?
  chain1.checkpoints.create!(
    created_by: users[:bob],
    amount: 15000,
    note: "First installment paid"
  )
end

puts "Created Chain 1: #{chain1.title} (Alice -> Bob, Charlie viewing)"

# Chain 2: Bob is creator and lender, Charlie is borrower, Diana and Alice are viewers
chain2 = Chain.find_or_create_by!(title: "Car Repair Loan") do |chain|
  chain.description = "Emergency car repair funds"
  chain.creator = users[:bob]
  chain.lender = users[:bob]
  chain.borrower = users[:charlie]
  chain.lent_money = 25000
  chain.outstanding = 25000
  chain.currency = "BDT"
  chain.status = :open
end

ChainParticipant.find_or_create_by!(chain: chain2, user: users[:bob]) do |cp|
  cp.role = :lender
end
ChainParticipant.find_or_create_by!(chain: chain2, user: users[:charlie]) do |cp|
  cp.role = :borrower
end
ChainParticipant.find_or_create_by!(chain: chain2, user: users[:diana]) do |cp|
  cp.role = :viewer
end
ChainParticipant.find_or_create_by!(chain: chain2, user: users[:alice]) do |cp|
  cp.role = :viewer
end

puts "Created Chain 2: #{chain2.title} (Bob -> Charlie, Diana & Alice viewing)"

# Chain 3: Charlie is creator and borrower, Diana is lender, Eve is viewer
chain3 = Chain.find_or_create_by!(title: "Medical Emergency") do |chain|
  chain.description = "Hospital bills coverage"
  chain.creator = users[:charlie]
  chain.lender = users[:diana]
  chain.borrower = users[:charlie]
  chain.lent_money = 100000
  chain.outstanding = 100000  # Will be reduced by checkpoint
  chain.currency = "BDT"
  chain.status = :open
end

ChainParticipant.find_or_create_by!(chain: chain3, user: users[:diana]) do |cp|
  cp.role = :lender
end
ChainParticipant.find_or_create_by!(chain: chain3, user: users[:charlie]) do |cp|
  cp.role = :borrower
end
ChainParticipant.find_or_create_by!(chain: chain3, user: users[:eve]) do |cp|
  cp.role = :viewer
end

if chain3.checkpoints.empty?
  chain3.checkpoints.create!(
    created_by: users[:charlie],
    amount: 25000,
    note: "Partial repayment"
  )
end

puts "Created Chain 3: #{chain3.title} (Diana -> Charlie, Eve viewing)"

# Chain 4: Diana is creator and lender, Alice is borrower (no extra participants)
chain4 = Chain.find_or_create_by!(title: "Business Investment") do |chain|
  chain.description = "Small business startup funding"
  chain.creator = users[:diana]
  chain.lender = users[:diana]
  chain.borrower = users[:alice]
  chain.lent_money = 150000
  chain.outstanding = 150000
  chain.currency = "BDT"
  chain.status = :open
end

ChainParticipant.find_or_create_by!(chain: chain4, user: users[:diana]) do |cp|
  cp.role = :lender
end
ChainParticipant.find_or_create_by!(chain: chain4, user: users[:alice]) do |cp|
  cp.role = :borrower
end

puts "Created Chain 4: #{chain4.title} (Diana -> Alice)"

# Chain 5: Eve is creator, Alice is lender, Bob is borrower, Charlie and Diana are viewers
chain5 = Chain.find_or_create_by!(title: "Travel Expenses") do |chain|
  chain.description = "Group trip expenses tracking"
  chain.creator = users[:eve]
  chain.lender = users[:alice]
  chain.borrower = users[:bob]
  chain.lent_money = 30000
  chain.outstanding = 30000  # Will be reduced by checkpoint
  chain.currency = "BDT"
  chain.status = :open
end

ChainParticipant.find_or_create_by!(chain: chain5, user: users[:alice]) do |cp|
  cp.role = :lender
end
ChainParticipant.find_or_create_by!(chain: chain5, user: users[:bob]) do |cp|
  cp.role = :borrower
end
ChainParticipant.find_or_create_by!(chain: chain5, user: users[:charlie]) do |cp|
  cp.role = :viewer
end
ChainParticipant.find_or_create_by!(chain: chain5, user: users[:diana]) do |cp|
  cp.role = :viewer
end

if chain5.checkpoints.empty?
  chain5.checkpoints.create!(
    created_by: users[:bob],
    amount: 20000,
    note: "Repaid portion of travel costs"
  )
end

puts "Created Chain 5: #{chain5.title} (Eve created, Alice -> Bob, Charlie & Diana viewing, #{chain5.outstanding} outstanding)"

# Chain 6: Closed chain - Alice is creator and lender, Bob is borrower
chain6 = Chain.find_or_create_by!(title: "Paid Off - Old Loan") do |chain|
  chain.description = "This loan has been fully repaid"
  chain.creator = users[:alice]
  chain.lender = users[:alice]
  chain.borrower = users[:bob]
  chain.lent_money = 10000
  chain.outstanding = 10000  # Will be reduced by checkpoint
  chain.currency = "BDT"
  chain.status = :open  # Will be set to closed by checkpoint
end

ChainParticipant.find_or_create_by!(chain: chain6, user: users[:alice]) do |cp|
  cp.role = :lender
end
ChainParticipant.find_or_create_by!(chain: chain6, user: users[:bob]) do |cp|
  cp.role = :borrower
end

if chain6.checkpoints.empty?
  chain6.checkpoints.create!(
    created_by: users[:bob],
    amount: 10000,
    note: "Fully repaid"
  )
end

puts "Created Chain 6: #{chain6.title} (Closed)"

puts "\n=========================================="
puts "Seeding complete!"
puts "=========================================="
puts "\nTest Users (password: password123):"
puts "  1. alice@example.com   - Creator/Lender role on multiple chains"
puts "  2. bob@example.com     - Lender/Creator on some, Borrower on others"
puts "  3. charlie@example.com - Borrower on some, Viewer on others"
puts "  4. diana@example.com   - Lender/Creator on some, Viewer on others"
puts "  5. eve@example.com     - Creator on some, Viewer on others"
puts "\nTo test the add participant feature:"
puts "  - Login as alice@example.com or bob@example.com (creator/lender)"
puts "    -> You should SEE the 'Add participant' form"
puts "  - Login as charlie@example.com or diana@example.com (borrower/viewer)"
puts "    -> You should NOT see the 'Add participant' form"
puts "=========================================="
